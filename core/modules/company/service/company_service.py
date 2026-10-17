from django.db import transaction

from core.models import Company


class CompanyService:
    @transaction.atomic
    def update(self, instance: Company, validated_data) -> Company:
        password = validated_data.pop("password", None)

        if password is not None:
            instance.set_password(password)

        for field, value in validated_data.items():
            setattr(instance, field, value)

        instance.save()
        return instance

    @transaction.atomic
    def delete(self, instance: Company) -> None:
        # Exclusão definitiva: apaga também os fatos e documentos da empresa.
        instance.delete()
