from rest_framework import generics
from rest_framework.permissions import IsAuthenticated

from core.classes.permission import CustomPermissionClass
from core.modules.company.serializer import CompanyDetailSerializer, CompanySerializer
from core.modules.company.service import CompanyService


class ViewCompanyMe(generics.RetrieveUpdateDestroyAPIView):
    """Dados da empresa logada. Não há como listar ou acessar outras empresas:
    o objeto é sempre o próprio request.user."""

    permission_classes = [IsAuthenticated, CustomPermissionClass]
    http_method_names = ["get", "patch", "delete", "head", "options"]

    def get_object(self):
        return self.request.user

    def get_serializer_class(self):
        if self.request.method == "GET":
            return CompanyDetailSerializer
        return CompanySerializer

    def perform_update(self, serializer):
        serializer.instance = self._service().update(
            serializer.instance, serializer.validated_data
        )

    def perform_destroy(self, instance):
        self._service().delete(instance)

    def _service(self) -> CompanyService:
        return CompanyService()
