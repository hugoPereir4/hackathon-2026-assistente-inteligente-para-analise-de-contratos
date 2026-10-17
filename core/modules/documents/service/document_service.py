from uuid import uuid4

from django.core.files.storage import default_storage
from PyPDF2 import PdfReader
from PyPDF2.errors import PdfReadError
from rest_framework.exceptions import ValidationError

from core.models import Company, Document


def extract_text_from_pdf(file_path: str) -> str:
    """Extrai texto de um arquivo PDF."""
    try:
        with default_storage.open(file_path, "rb") as pdf_file:
            reader = PdfReader(pdf_file)
            if reader.is_encrypted:
                raise ValidationError(
                    {"file": ["Envie um PDF sem proteção por senha."]}
                )
            return "\n".join(page.extract_text() or "" for page in reader.pages).strip()
    except (PdfReadError, KeyError, ValueError) as exc:
        raise ValidationError({
            "file": ["Não foi possível ler o PDF. O arquivo pode estar corrompido."]
        }) from exc


def create_document(*, company: Company, uploaded_file, doc_type: str | None) -> Document:
    filename = uploaded_file.name.replace("\\", "/").rsplit("/", 1)[-1][:255]
    storage_path = f"documents/{company.pk}/{uuid4().hex}.pdf"
    saved_path = default_storage.save(storage_path, uploaded_file)

    try:
        text_content = extract_text_from_pdf(saved_path)

        return Document.objects.create(
            company=company,
            doc_type=doc_type,
            filename=filename,
            file_path=saved_path,
            text_content=text_content,
        )
    except Exception:
        # Falhas na extração ou persistência não devem deixar arquivos órfãos.
        default_storage.delete(saved_path)
        raise


def delete_document(document: Document) -> None:
    default_storage.delete(document.file_path)
    document.delete()
