"""Upload regression tests using production routes, real PDFs and JWT."""

from io import BytesIO
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

from django.conf import settings
from django.core.files.storage import default_storage
from django.core.files.uploadedfile import SimpleUploadedFile
from django.db import DatabaseError
from django.test import override_settings
from PyPDF2 import PdfWriter
from PyPDF2.generic import (
    DecodedStreamObject,
    DictionaryObject,
    NameObject,
)
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import AccessToken

from core.models import Company, Document


def pdf_bytes(*, encrypted=False):
    writer = PdfWriter()
    writer.add_blank_page(width=612, height=792)
    page = writer.pages[0]
    font = DictionaryObject({
        NameObject("/Type"): NameObject("/Font"),
        NameObject("/Subtype"): NameObject("/Type1"),
        NameObject("/BaseFont"): NameObject("/Helvetica"),
    })
    page[NameObject("/Resources")] = DictionaryObject({
        NameObject("/Font"): DictionaryObject({NameObject("/F1"): font}),
    })
    stream = DecodedStreamObject()
    stream.set_data(b"BT /F1 12 Tf 72 720 Td (Contrato de teste) Tj ET")
    page[NameObject("/Contents")] = stream
    if encrypted:
        writer.encrypt("senha-de-teste")
    output = BytesIO()
    writer.write(output)
    return output.getvalue()


class DocumentUploadTests(APITestCase):
    @classmethod
    def setUpTestData(cls):
        cls.company = Company.objects.create_company(
            email="upload@example.com", cnpj="12345678000195",
            password="Upload-Test-2026!",
        )
        cls.other = Company.objects.create_company(
            email="other-upload@example.com", cnpj="98765432000198",
            password="Upload-Test-2026!",
        )

    def setUp(self):
        media = TemporaryDirectory()
        self.addCleanup(media.cleanup)
        self.media = Path(media.name)
        override = override_settings(MEDIA_ROOT=self.media)
        override.enable()
        self.addCleanup(override.disable)
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {AccessToken.for_user(self.company)}"
        )
        # Inspect actual HTTP 500 responses instead of re-raising their exception.
        self.client.raise_request_exception = False

    def upload(self, content=None, name="contract.pdf", **extra):
        return self.client.post(
            "/api/v1/documents/",
            {"file": SimpleUploadedFile(
                name, pdf_bytes() if content is None else content,
                content_type="application/pdf",
            ), **extra},
            format="multipart",
        )

    def assert_rejected(self, response, expected=400):
        self.assertEqual(response.status_code, expected)
        self.assertFalse(Document.objects.exists())
        self.assertEqual(list(self.media.rglob("*.pdf")), [])

    def test_valid_pdf_is_stored_and_text_is_extracted(self):
        response = self.upload(doc_type="contract")
        exc_info = getattr(response, "exc_info", None)
        error = str(exc_info[1]) if exc_info else ""
        self.assertEqual(response.status_code, 201, error)
        document = Document.objects.get(pk=response.data["id"])
        self.assertEqual(document.company, self.company)
        self.assertEqual(document.text_content, "Contrato de teste")
        self.assertTrue(default_storage.exists(document.file_path))
        with default_storage.open(document.file_path, "rb") as stored:
            self.assertEqual(stored.read(), pdf_bytes())
        self.assertNotIn("file_path", response.data)

    def test_upload_requires_authentication(self):
        self.client.credentials()
        self.assert_rejected(self.upload(), 401)

    def test_upload_rejects_invalid_token(self):
        self.client.credentials(HTTP_AUTHORIZATION="Bearer invalid")
        self.assert_rejected(self.upload(), 401)

    def test_upload_requires_file(self):
        self.assert_rejected(self.client.post(
            "/api/v1/documents/", {}, format="multipart"
        ))

    def test_empty_file_is_rejected(self):
        self.assert_rejected(self.upload(content=b""))

    def test_non_pdf_extension_is_rejected(self):
        self.assert_rejected(self.upload(name="contract.docx"))

    def test_fake_pdf_without_signature_is_rejected(self):
        self.assert_rejected(self.upload(content=b"not a PDF"))

    def test_invalid_document_type_is_rejected(self):
        self.assert_rejected(self.upload(doc_type="unknown"))

    def test_file_over_10_mb_is_rejected(self):
        self.assertEqual(settings.MAX_DOCUMENT_UPLOAD_SIZE, 10 * 1024 * 1024)
        self.assert_rejected(self.upload(
            content=b"%PDF-" + b"x" * settings.MAX_DOCUMENT_UPLOAD_SIZE
        ))

    def test_file_exactly_10_mb_is_accepted(self):
        content = pdf_bytes()
        content += b"\n%" + b"x" * (
            settings.MAX_DOCUMENT_UPLOAD_SIZE - len(content) - 2
        )
        self.assertEqual(self.upload(content=content).status_code, 201)

    def test_uppercase_pdf_extension_is_accepted(self):
        self.assertEqual(self.upload(name="contract.PDF").status_code, 201)

    def test_corrupt_pdf_is_rejected_without_orphan_file(self):
        self.assert_rejected(self.upload(content=b"%PDF-1.4\ncorrupt"))

    def test_encrypted_pdf_is_rejected_without_orphan_file(self):
        self.assert_rejected(self.upload(content=pdf_bytes(encrypted=True)))

    def test_failed_upload_does_not_leave_orphan_file(self):
        self.upload(content=b"%PDF-1.4\ncorrupt")
        self.assertFalse(Document.objects.exists())
        self.assertEqual(list(self.media.rglob("*.pdf")), [])

    @patch("core.modules.documents.service.document_service.Document.objects.create",
           side_effect=DatabaseError("Simulated database failure"))
    def test_database_failure_removes_stored_file(self, _create):
        self.assert_rejected(self.upload(), 500)

    @patch("core.modules.documents.service.document_service.extract_text_from_pdf",
           side_effect=OSError("Simulated read failure"))
    def test_unexpected_extraction_failure_removes_stored_file(self, _extract):
        self.assert_rejected(self.upload(), 500)

    def test_pdf_without_text_can_be_stored(self):
        writer = PdfWriter()
        writer.add_blank_page(width=612, height=792)
        content = BytesIO()
        writer.write(content)
        response = self.upload(content=content.getvalue())
        self.assertEqual(response.status_code, 201)
        document = Document.objects.get(pk=response.data["id"])
        self.assertEqual(document.text_content, "")
        self.assertEqual(document.status, "uploaded")

    def test_list_hides_other_company_documents(self):
        own = self.company.documents.create(filename="own.pdf", file_path="own.pdf")
        self.other.documents.create(filename="other.pdf", file_path="other.pdf")
        response = self.client.get("/api/v1/documents/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual([item["id"] for item in response.data["results"]], [own.pk])

    def test_other_company_document_cannot_be_read_or_deleted(self):
        document = self.other.documents.create(
            filename="private.pdf", file_path="private.pdf"
        )
        url = f"/api/v1/documents/{document.pk}/"
        self.assertEqual(self.client.get(url).status_code, 404)
        self.assertEqual(self.client.delete(url).status_code, 404)
        self.assertTrue(Document.objects.filter(pk=document.pk).exists())

    def test_delete_removes_existing_document_and_file(self):
        stored = default_storage.save(
            "documents/delete.pdf", SimpleUploadedFile("delete.pdf", pdf_bytes())
        )
        document = self.company.documents.create(filename="delete.pdf", file_path=stored)
        self.assertEqual(
            self.client.delete(f"/api/v1/documents/{document.pk}/").status_code, 204
        )
        self.assertFalse(Document.objects.filter(pk=document.pk).exists())
        self.assertFalse(default_storage.exists(stored))
