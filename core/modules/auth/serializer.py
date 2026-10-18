from django.contrib.auth.password_validation import validate_password
from django.utils.translation import gettext_lazy as _
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from core.models import Company
from core.modules.auth.service import display_name
from core.modules.company.validators import normalize_cnpj


class LoginSerializer(TokenObtainPairSerializer):
    # Aceita email ou CNPJ; ver core.classes.auth_backend.EmailOrCnpjBackend.
    username_field = "login"

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["name"] = display_name(user)
        return token


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    # Aceita o CNPJ com pontuação (até 18 caracteres); é salvo só com os 14.
    cnpj = serializers.CharField(max_length=18)

    class Meta:
        model = Company
        # Os campos além de email/password/cnpj são opcionais e vêm da
        # consulta GET /companies/{cnpj}/ (Minha Receita).
        fields = (
            "id",
            "email",
            "password",
            "cnpj",
            "legal_name",
            "cnae_primary",
            "company_size",
            "founded_on",
            "address_city",
            "address_state",
        )
        read_only_fields = ("id",)
        extra_kwargs = {"email": {"validators": []}}

    def validate_email(self, value):
        email = Company.objects.normalize_email(value.strip().lower())
        if Company.objects.filter(email=email).exists():
            raise serializers.ValidationError(_("Já existe uma conta com este email."))
        return email

    def validate_cnpj(self, value):
        cnpj = normalize_cnpj(value)
        if Company.objects.filter(cnpj=cnpj).exists():
            raise serializers.ValidationError(_("Já existe uma conta com este CNPJ."))
        return cnpj

    def validate(self, attrs):
        validate_password(attrs["password"], user=Company(email=attrs.get("email")))
        return attrs
