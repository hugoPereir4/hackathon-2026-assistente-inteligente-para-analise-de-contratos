from rest_framework.permissions import IsAuthenticated

from core.classes.base_viewset import BaseModelViewSet
from core.classes.permission import CustomPermissionClass
from core.models import Document
from core.modules.documents.serializer import DocumentDetailSerializer, DocumentSerializer
from core.modules.documents.service import delete_document
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status
from core.modules.documents.service import analyze_document_with_ai
from core.modules.documents.service.ai_service import (
    AIAnalysisError, AnalysisInputError, AnalysisStateError,
)



class DocumentViewSet(BaseModelViewSet):
    permission_classes = [IsAuthenticated, CustomPermissionClass]
    serializer_class = DocumentSerializer
    http_method_names = ["get", "post", "delete", "head", "options"]

    def get_serializer_class(self):
        if self.action in ("retrieve", "analyze"):
            return DocumentDetailSerializer
        return DocumentSerializer

    def get_queryset(self):
        return Document.objects.filter(company=self.request.user).order_by("-created_at")

    def perform_create(self, serializer):
        serializer.save(company=self.request.user)

    def perform_destroy(self, instance):
        delete_document(instance)

    @action(detail=True, methods=["post"])
    def analyze(self, request, pk=None):
        document = self.get_object()

        try:
            analyze_document_with_ai(document)
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
                {"error": str(e)},
                status=status.HTTP_502_BAD_GATEWAY,
            )
