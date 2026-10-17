from core.modules.documents.service.document_service import (
    create_document,
    delete_document,
)
from core.modules.documents.service.ai_service import analyze_document_with_ai

__all__ = ["create_document", "delete_document", "analyze_document_with_ai"]