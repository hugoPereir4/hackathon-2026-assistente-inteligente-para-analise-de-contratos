from rest_framework.permissions import IsAuthenticated

from core.classes.base_viewset import BaseModelViewSet
from core.classes.permission import CustomPermissionClass
from core.models import Document
from core.modules.documents.serializer import DocumentSerializer
from core.modules.documents.service import delete_document
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status
from core.modules.documents.service import analyze_document_with_ai



class DocumentViewSet(BaseModelViewSet):
    permission_classes = [IsAuthenticated, CustomPermissionClass]
    serializer_class = DocumentSerializer
    http_method_names = ["get", "post", "delete", "head", "options"]

    def get_queryset(self):
        return Document.objects.filter(company=self.request.user).order_by("-created_at")

    def perform_create(self, serializer):
        serializer.save(company=self.request.user)

    def perform_destroy(self, instance):
        delete_document(instance)

    @action(detail=True, methods=["post"])
    def analyze(self, request, pk=None):
        document = self.get_object()

        if document.status != Document.Status.UPLOADED:
            return Response(
                {"error": "O documento já foi analisado ou está em processamento."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            analyze_document_with_ai(document)
            return Response(
                {"message": "Análise iniciada com sucesso.", "status": document.status},
                status=status.HTTP_200_OK,
            )
        except ValueError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except requests.RequestException as e:
            return Response(
                {"error": "Erro ao se comunicar com a IA.", "details": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
