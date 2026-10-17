import re

from django.utils.translation import gettext_lazy as _
from rest_framework import serializers

_CNPJ_FORMAT = re.compile(r"^[0-9A-Z]{12}[0-9]{2}$")
_WEIGHTS = (6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2)


def _check_digit(base: str) -> int:
    weights = _WEIGHTS[-len(base):]
    total = sum((ord(char) - 48) * weight for char, weight in zip(base, weights))
    remainder = total % 11
    return 0 if remainder < 2 else 11 - remainder


def normalize_cnpj(value: str) -> str:
    """Remove a pontuação e valida o CNPJ (numérico ou alfanumérico)."""
    cnpj = re.sub(r"[.\-/\s]", "", value or "").upper()

    if not _CNPJ_FORMAT.match(cnpj) or len(set(cnpj)) == 1:
        raise serializers.ValidationError(_("CNPJ inválido."))

    first = _check_digit(cnpj[:12])
    second = _check_digit(cnpj[:12] + str(first))
    if cnpj[12:] != f"{first}{second}":
        raise serializers.ValidationError(_("CNPJ inválido."))

    return cnpj
