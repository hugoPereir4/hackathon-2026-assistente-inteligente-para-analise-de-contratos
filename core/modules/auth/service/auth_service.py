from core.models import Company


def display_name(user) -> str:
    return user.legal_name or user.email


def register(validated_data) -> Company:
    return Company.objects.create_company(**validated_data)
