from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from uuid import UUID

from core.classes.base_viewset import BaseModelViewSet
from core.classes.permission import CustomPermissionClass
from core.models import Document
from core.modules.documents.serializer import (
    DocumentAnalysisRequestSerializer, DocumentDetailSerializer, DocumentSerializer,
)
from core.modules.documents.service import delete_document
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status
from core.modules.documents.service import analyze_document_with_ai
from core.modules.documents.service.ai_service import (
    AIAnalysisError, AnalysisInputError, AnalysisStateError, reanalyze_document_with_ai,
)
from core.modules.documents.service.answer_service import (
    AnswerConflictError, preview_answers, confirm_answer_batch,
)
from core.modules.documents.answer_serializer import (
    AnswerPreviewSerializer, AnswerConfirmationSerializer, DocumentAnswerBatchSerializer,
)



class DocumentViewSet(BaseModelViewSet):
    permission_classes = [IsAuthenticated, CustomPermissionClass]
    serializer_class = DocumentSerializer
    http_method_names = ["get", "post", "delete", "head", "options"]

    def get_serializer_class(self):
        if self.action in ("retrieve", "analyze", "reanalyze"):
            return DocumentDetailSerializer
        return DocumentSerializer

    def get_queryset(self):
        return Document.objects.filter(company=self.request.user).select_related("company").order_by("-created_at")

    def perform_create(self, serializer):
        serializer.save(company=self.request.user)

    def perform_destroy(self, instance):
        delete_document(instance)

    @action(detail=True, methods=["post"])
    def analyze(self, request, pk=None):
        document = self.get_object()
        options = DocumentAnalysisRequestSerializer(data=request.data)
        options.is_valid(raise_exception=True)

        try:
            analyze_document_with_ai(
                document, retry_failed=options.validated_data["retry_failed"],
            )
            return Response(
                self.get_serializer(document).data,
                status=status.HTTP_200_OK,
            )
        except AnalysisStateError as e:
            return Response({"error": str(e)}, status=status.HTTP_409_CONFLICT)
        except AnalysisInputError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except AIAnalysisError as e:
            return Response(
                self._error_payload(e),
                status=status.HTTP_502_BAD_GATEWAY,
            )

    @staticmethod
    def _error_payload(exc):
        payload = {"error": str(exc)}
        diagnostic_id = getattr(exc, "diagnostic_id", None)
        if diagnostic_id:
            payload["diagnostic_id"] = diagnostic_id
            payload["error"] += f" Código para suporte: {diagnostic_id}."
        return payload

    @staticmethod
    def _flow_error(exc):
        if isinstance(exc, (AnswerConflictError, AnalysisStateError)):
            code = status.HTTP_409_CONFLICT
        elif isinstance(exc, AnalysisInputError):
            code = status.HTTP_400_BAD_REQUEST
        else:
            code = status.HTTP_502_BAD_GATEWAY
        return Response(DocumentViewSet._error_payload(exc), status=code)

    @action(detail=True, methods=["post"], url_path="answers/preview")
    def answers_preview(self, request, pk=None):
        document = self.get_object()
        serializer = AnswerPreviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            batch = preview_answers(document, serializer.validated_data["respostas"])
        except (AnswerConflictError, AnalysisInputError, AIAnalysisError) as exc:
            return self._flow_error(exc)
        return Response(DocumentAnswerBatchSerializer(batch).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["post"], url_path=r"answers/(?P<batch_id>[^/.]+)/confirm")
    def answers_confirm(self, request, pk=None, batch_id=None):
        document = self.get_object()
        try:
            batch_uuid = UUID(batch_id)
        except (ValueError, TypeError):
            return Response({"error": "Lote não encontrado."}, status=status.HTTP_404_NOT_FOUND)
        batch = get_object_or_404(document.answer_batches, pk=batch_uuid)
        serializer = AnswerConfirmationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            batch = confirm_answer_batch(
                document, batch, serializer.validated_data["propostas_aprovadas"],
                serializer.validated_data["autorizar_substituicao"],
            )
        except (AnswerConflictError, AnalysisInputError, AnalysisStateError) as exc:
            return self._flow_error(exc)
        document.refresh_from_db()
        return Response({
            "lote": DocumentAnswerBatchSerializer(batch).data, "respostas_salvas": True,
            "reavaliacao": {
                "status": batch.reanalysis_status, "erro": batch.reanalysis_error or None,
            },
            "documento": DocumentDetailSerializer(document, context=self.get_serializer_context()).data,
        })

    @action(detail=True, methods=["post"])
    def reanalyze(self, request, pk=None):
        document = self.get_object()
        try:
            reanalyze_document_with_ai(document)
        except (AnalysisInputError, AnalysisStateError, AIAnalysisError) as exc:
            return self._flow_error(exc)
        return Response(self.get_serializer(document).data)
