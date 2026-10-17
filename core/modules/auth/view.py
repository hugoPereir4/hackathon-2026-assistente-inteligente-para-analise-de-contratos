from django.db import transaction
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from core.modules.auth.serializer import LoginSerializer, RegisterSerializer
from core.modules.auth.service import register


class ViewTokenObtainPair(TokenObtainPairView):
    throttle_scope = "login"
    serializer_class = LoginSerializer


class ViewRegister(APIView):
    permission_classes = [permissions.AllowAny]

    @transaction.atomic
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = register(serializer.validated_data)

        token = LoginSerializer.get_token(user)
        return Response(
            data={
                "user": RegisterSerializer(user).data,
                "access": str(token.access_token),
                "refresh": str(token),
            },
            status=status.HTTP_201_CREATED,
        )
