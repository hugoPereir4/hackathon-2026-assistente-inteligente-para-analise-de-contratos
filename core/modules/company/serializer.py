from rest_framework import serializers
from core.models import Company
from django.contrib.auth.password_validation import validate_password

COMPANY_FIELDS = (
    "id",
    "cnpj",
    "email",
    "legal_name",
    "cnae_primary",
    "company_size",
    "founded_on",
    "address_city",
    "address_state",
    "confirmed",
    "created_at",
)
READ_ONLY_FIELDS = ("id", "cnpj", "created_at")


class CompanySerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = Company
        fields = COMPANY_FIELDS + ("password",)
        read_only_fields = READ_ONLY_FIELDS

    def validate_password(self, value):
        validate_password(value, user=self.instance)
        return value


class CompanyDetailSerializer(serializers.ModelSerializer):
    class Meta:
        model = Company
        fields = COMPANY_FIELDS
        read_only_fields = READ_ONLY_FIELDS
