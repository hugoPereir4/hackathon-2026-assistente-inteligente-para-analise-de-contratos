"""Contrato da IA; indicadores e metadados são adicionados pelo backend."""
from datetime import date
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field

Text = Annotated[str, Field(min_length=1, pattern=r"\S")]
DecimalText = Annotated[str, Field(pattern=r"^-?\d+(\.\d+)?$")]


class Schema(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)


class Evidence(Schema):
    trecho: Text
    clausula: Text | None


class CompanyRole(Schema):
    papel: Literal["contratante", "fornecedora", "desconhecido"]
    justificativa: Text
    evidencia: Evidence | None


class Deadline(Schema):
    id: Text
    descricao: Text
    data: date | None
    prazo_relativo: Text | None
    evento_referencia: Text | None
    evidencia: Evidence


class Amount(Schema):
    descricao: Text
    categoria: Literal["valor_total", "pagamento", "multa", "garantia", "outro"]
    moeda: Text | None
    montante: DecimalText | None
    percentual: DecimalText | None
    aproximado: bool
    evidencia: Evidence


class Obligation(Schema):
    descricao: Text
    parte_responsavel: Text | None
    prazo_id: Text | None
    evidencia: Evidence


class Risk(Schema):
    descricao: Text
    severidade: Literal["baixa", "media", "alta", "critica"]
    impacto: Text
    recomendacao: Text
    evidencia: Evidence


class Requirement(Schema):
    id: Text
    descricao: Text
    obrigatorio: bool
    resultado: Literal["atende", "nao_atende", "desconhecido"]
    depende_papel: bool
    justificativa: Text
    evidencia: Evidence
    referencias_perfil: list[Text]


class Question(Schema):
    id: Text
    pergunta: Text
    requisito_ids: list[Text]
    fato_chave: Text | None
    sobre_papel: bool


class DocumentAnalysis(Schema):
    resumo: Text
    papel_empresa: CompanyRole
    prazos: list[Deadline]
    valores: list[Amount]
    obrigacoes: list[Obligation]
    riscos: list[Risk]
    requisitos: list[Requirement]
    perguntas_pendentes: list[Question]
