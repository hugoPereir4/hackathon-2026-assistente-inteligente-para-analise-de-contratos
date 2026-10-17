from rest_framework import generics, serializers
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.classes.permission import CustomPermissionClass
from core.modules.company.serializer import CompanyDetailSerializer, CompanySerializer
from core.modules.company.service import CnpjService, CompanyService
from core.modules.company.validators import normalize_cnpj


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


class ViewCompanyCnpjLookup(APIView):
    """Consulta o CNPJ na Minha Receita para o front preencher o cadastro.
    Pública (o usuário ainda não tem conta) e não salva nada."""

    permission_classes = [AllowAny]
    http_method_names = ["get", "head", "options"]

    def get(self, request, cnpj):
        try:
            cnpj = normalize_cnpj(cnpj)
        except serializers.ValidationError as error:
            raise ValidationError({"cnpj": error.detail})

        return Response(CnpjService().lookup(cnpj))
