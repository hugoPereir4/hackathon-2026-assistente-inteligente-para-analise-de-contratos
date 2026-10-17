from django.db import transaction
from django.utils.translation import gettext_lazy as _
from rest_framework import viewsets
from rest_framework.response import Response


class BaseModelViewSet(viewsets.ModelViewSet):

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        res = super().create(request, *args, **kwargs)
        return Response(data=res.data, status=res.status_code)

    @transaction.atomic
    def update(self, request, *args, **kwargs):
        res = super().update(request, *args, **kwargs)
        return Response(data=res.data, status=res.status_code)

    def list(self, request, *args, **kwargs):
        res = super().list(request, *args, **kwargs)
        return Response(data=res.data, status=res.status_code)

    def retrieve(self, request, *args, **kwargs):
        res = super().retrieve(request, *args, **kwargs)
        return Response(data=res.data, status=res.status_code)

    @transaction.atomic
    def destroy(self, request, *args, **kwargs):
        res = super().destroy(request, *args, **kwargs)
        return Response(
            data={"message": _("Registro deletado com sucesso!")},
            status=res.status_code,
        )