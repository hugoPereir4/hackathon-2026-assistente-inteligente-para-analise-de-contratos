"""Contrato da IA. O score vem da IA; cobertura, outcome e metadados são do backend."""
from datetime import date
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field

Text = Annotated[str, Field(min_length=1, pattern=r"\S")]
DecimalText = Annotated[str, Field(pattern=r"^-?\d+(\.\d+)?$")]
ValueType = Literal["booleano", "inteiro", "decimal", "texto", "data", "objeto"]
ScalarType = Literal["booleano", "inteiro", "decimal", "texto", "data"]
Score = Annotated[int, Field(ge=0, le=100)]


class Schema(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)


class Evidence(Schema):
    trecho: Text
    clausula: Text | None


class EvidenceCorrection(Schema):
    caminho: Text
    linha_inicio: Annotated[int, Field(ge=1)]
    linha_fim: Annotated[int, Field(ge=1)]


class EvidenceCorrections(Schema):
    correcoes: list[EvidenceCorrection]


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
    resultado: Literal["atende", "parcialmente_atende", "nao_atende", "desconhecido"]
    depende_papel: bool
    justificativa: Text
    evidencia: Evidence
    referencias_perfil: list[Text]


class Question(Schema):
    id: Text
    pergunta: Text
    requisito_ids: list[Text]
    fato_chave: Text | None
    destino: Literal["company_fact", "cadastro"]
    fato_rotulo: Annotated[str, Field(min_length=1, max_length=255, pattern=r"\S")] | None
    tipo_valor: ValueType | None


class DocumentAnalysis(Schema):
    resumo: Text
    papel_empresa: CompanyRole
    prazos: list[Deadline]
    valores: list[Amount]
    obrigacoes: list[Obligation]
    riscos: list[Risk]
    requisitos: list[Requirement]
    perguntas_pendentes: list[Question]
    # Por último: a IA atribui a nota depois de extrair e comparar tudo.
    score: Score
    justificativa_score: Text


class RequirementsAudit(Schema):
    requisitos_adicionais: list[Requirement]
    perguntas_adicionais: list[Question]


class InterpretedAnswer(Schema):
    pergunta_id: Text
    suficiente: bool
    justificativa: Text
    esclarecimento: Text | None
    tipo_valor: ValueType | None
    valor: bool | int | str | dict[str, bool | int | str] | None
    tipos_campos: dict[str, ScalarType] | None


class AnswerInterpretation(Schema):
    respostas: list[InterpretedAnswer]
