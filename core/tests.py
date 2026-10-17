import os
import shutil
import tempfile

from django.core.cache import cache
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import Company
from core.test_document_upload import pdf_bytes


class DocumentApiTests(APITestCase):
    def setUp(self):
        cache.clear()
        self.media_dir = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.media_dir, ignore_errors=True)
        media_settings = override_settings(MEDIA_ROOT=self.media_dir)
        media_settings.enable()
        self.addCleanup(media_settings.disable)

        self.company = Company.objects.create(
            email="company@example.com",
            cnpj="12345678000199",
            password="hashed-password",
        )
        self.other_company = Company.objects.create(
            email="other@example.com",
            cnpj="98765432000198",
            password="hashed-password",
        )
        self.client.force_authenticate(user=self.company)

    def _pdf_upload(self, name="contract.pdf", content=None):
        if content is None:
            content = pdf_bytes()
        return SimpleUploadedFile(name, content, content_type="application/pdf")

    def test_upload_and_list_only_current_company_documents(self):
        response = self.client.post(
            "/api/v1/documents/",
            {"file": self._pdf_upload(), "doc_type": "contract"},
            format="multipart",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["filename"], "contract.pdf")
        self.assertEqual(response.data["status"], "uploaded")
        self.assertNotIn("file_path", response.data)

        detail_response = self.client.get(
            f"/api/v1/documents/{response.data['id']}/"
        )
        self.assertEqual(detail_response.status_code, status.HTTP_200_OK)

        list_response = self.client.get("/api/v1/documents/")
        self.assertEqual(list_response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(list_response.data["results"]), 1)

    def test_upload_rejects_invalid_pdf_content(self):
        response = self.client.post(
            "/api/v1/documents/",
            {"file": self._pdf_upload(content=b"not a PDF")},
            format="multipart",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(self.company.documents.exists())

    def test_upload_rejects_non_pdf_files(self):
        response = self.client.post(
            "/api/v1/documents/",
            {"file": self._pdf_upload("contract.docx")},
            format="multipart",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(self.company.documents.exists())

    def test_upload_rejects_files_over_configured_limit(self):
        response = self.client.post(
            "/api/v1/documents/",
            {"file": self._pdf_upload(content=b"%PDF-" + b"x" * (10 * 1024 * 1024))},
            format="multipart",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(self.company.documents.exists())

    def test_company_cannot_access_another_company_document(self):
        document = self.other_company.documents.create(
            filename="private.pdf",
            file_path="documents/private.pdf",
        )

        response = self.client.get(f"/api/v1/documents/{document.pk}/")

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_delete_removes_document_and_stored_file(self):
        upload_response = self.client.post(
            "/api/v1/documents/",
            {"file": self._pdf_upload()},
            format="multipart",
        )
        document_id = upload_response.data["id"]
        document = self.company.documents.get(pk=document_id)
        stored_path = os.path.join(self.media_dir, document.file_path)

        response = self.client.delete(f"/api/v1/documents/{document_id}/")

        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(self.company.documents.filter(pk=document_id).exists())
        self.assertFalse(os.path.exists(stored_path))
