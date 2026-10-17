import re

from django.contrib.auth.backends import ModelBackend

from core.models import Company


class EmailOrCnpjBackend(ModelBackend):
    """Autentica com email ou CNPJ (com ou sem pontuação) no campo `login`."""

    def authenticate(self, request, login=None, password=None, **kwargs):
        if login is None or password is None:
            return None

        if "@" in login:
            lookup = {"email": login.strip().lower()}
        else:
            lookup = {"cnpj": re.sub(r"[.\-/\s]", "", login).upper()}

        try:
            company = Company.objects.get(**lookup)
        except Company.DoesNotExist:
            # Roda o hasher mesmo assim para não revelar, pelo tempo de
            # resposta, se a conta existe.
            Company().set_password(password)
            return None

        if company.check_password(password) and self.user_can_authenticate(company):
            return company
        return None
