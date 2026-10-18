import json
from datetime import date
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from django.utils.translation import gettext_lazy as _
from rest_framework import status
from rest_framework.exceptions import APIException, NotFound

MINHA_RECEITA_URL = "https://minhareceita.org/{cnpj}"
TIMEOUT_SECONDS = 10


class CnpjApiUnavailable(APIException):
    status_code = status.HTTP_502_BAD_GATEWAY
    default_detail = _("Não foi possível consultar a Receita agora. Tente novamente.")
    default_code = "cnpj_api_unavailable"


class CnpjService:
    def lookup(self, cnpj: str) -> dict:
        """Busca o CNPJ na Minha Receita e devolve os dados já com os nomes
        dos campos da tabela company. Não salva nada."""
        data = self._fetch(cnpj)
        return {
            "cnpj": cnpj,
            "legal_name": data.get("razao_social") or None,
            "cnae_primary": self._format_cnae(data.get("cnae_fiscal")),
            "company_size": data.get("porte") or None,
            "founded_on": self._parse_date(data.get("data_inicio_atividade")),
            "address_city": data.get("municipio") or None,
            "address_state": data.get("uf") or None,
        }

    def _fetch(self, cnpj: str) -> dict:
        request = Request(
            MINHA_RECEITA_URL.format(cnpj=cnpj),
            headers={"Accept": "application/json", "User-Agent": "assistente-contratos"},
        )
        try:
            with urlopen(request, timeout=TIMEOUT_SECONDS) as response:
                return json.loads(response.read().decode("utf-8"))
        except HTTPError as error:
            if error.code in (400, 404):
                raise NotFound(_("CNPJ não encontrado na Receita."))
            raise CnpjApiUnavailable()
        except (URLError, TimeoutError, ValueError):
            raise CnpjApiUnavailable()

    def _format_cnae(self, value) -> str | None:
        # 6201501 -> "6201-5/01"
        if not value:
            return None
        code = str(value).zfill(7)
        return f"{code[:4]}-{code[4]}/{code[5:]}"

    def _parse_date(self, value) -> date | None:
        try:
            return date.fromisoformat(value) if value else None
        except ValueError:
            return None
