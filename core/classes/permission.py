from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import BasePermission


class CustomPermissionClass(BasePermission):

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            self._raise_permission_denied()

        return True

    def _raise_permission_denied(self):
        raise PermissionDenied(
            {
                "success": False,
                "status": 403,
                "message": "Sem permissão para acessar o recurso.",
                "data": {},
                "error": {},
            }
        )


class SafeDefaultPermission(BasePermission):

    SAFE_METHODS = frozenset({"GET", "HEAD", "OPTIONS"})
    message = (
        "ViewSet sem permission_classes declarado. "
        "Operações destrutivas estão bloqueadas pela rede de segurança "
        "(SafeDefaultPermission). Declare permission_classes na classe."
    )

    def has_permission(self, request, view):
        return request.method in self.SAFE_METHODS