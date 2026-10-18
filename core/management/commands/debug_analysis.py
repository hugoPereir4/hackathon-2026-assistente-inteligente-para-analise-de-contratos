"""Captura uma execução sem alterar o documento ou reproduz validações offline."""
import json
from pathlib import Path

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError

from core.models import Document
from core.modules.documents.service.analysis_schema import DocumentAnalysis
from core.modules.documents.service.ai_service import (
    AIAnalysisError, EvidenceValidationError, _repair_analysis_evidence,
    build_company_context, generate_validated_analysis, validate_analysis,
)
from core.modules.documents.service.diagnostics import capture_analysis


class Command(BaseCommand):
    help = "Diagnostica análise sem alterar banco; --replay valida o registro sem chamar a IA."

    def add_arguments(self, parser):
        group = parser.add_mutually_exclusive_group(required=True)
        group.add_argument("--document", type=int)
        group.add_argument("--replay", type=Path)
        group.add_argument("--repair-from", type=Path)

    def handle(self, *args, **options):
        if options["repair_from"]:
            trace = json.loads(options["repair_from"].read_text(encoding="utf-8"))
            event = next(e for e in trace["events"] if e["event"] == "validation_input")
            analysis = DocumentAnalysis.model_validate_json(json.dumps(event["analysis"]))
            with capture_analysis(trace["document_id"], force=True) as repaired_trace:
                try:
                    validate_analysis(analysis, event["text"], event["context"])
                except EvidenceValidationError as exc:
                    repaired = _repair_analysis_evidence(analysis, event["text"], exc.paths)
                    validate_analysis(repaired, event["text"], event["context"])
            self.stdout.write("Resposta capturada corrigida e validada (banco inalterado).")
            self.stdout.write(str(Path(settings.AI_DIAGNOSTICS_DIR) / f"{repaired_trace['id']}.json"))
            return
        if options["replay"]:
            trace = json.loads(options["replay"].read_text(encoding="utf-8"))
            request = None
            for index, event in enumerate(trace["events"]):
                if event["event"] == "provider_request":
                    request = event
                if (event["event"] == "provider_response" and request
                        and request["schema"].get("title") == "EvidenceCorrections"):
                    response = json.loads(event["text"])
                    expected = {item["caminho"] for item in request["data"]["itens"]}
                    actual = {item["caminho"] for item in response["correcoes"]}
                    if actual != expected:
                        self.stdout.write(f"Etapa {index}: caminhos divergentes: esperados={sorted(expected)}, recebidos={sorted(actual)}")
                if event["event"] != "validation_input":
                    continue
                analysis = DocumentAnalysis.model_validate_json(json.dumps(event["analysis"]))
                try:
                    validate_analysis(analysis, event["text"], event["context"])
                    self.stdout.write(f"Etapa {index}: validada")
                except AIAnalysisError as exc:
                    self.stdout.write(f"Etapa {index}: {exc}; campos={getattr(exc, 'paths', [])}")
            return
        try:
            document = Document.objects.select_related("company").get(pk=options["document"])
        except Document.DoesNotExist as exc:
            raise CommandError("Documento não encontrado.") from exc
        with_trace = None
        try:
            with capture_analysis(document.pk, force=True) as with_trace:
                generate_validated_analysis(document, build_company_context(document.company))
            self.stdout.write("Resultado validado (banco inalterado).")
        except AIAnalysisError as exc:
            self.stdout.write(f"Falha reproduzida: {exc}")
        finally:
            if with_trace:
                self.stdout.write(str(Path(settings.AI_DIAGNOSTICS_DIR) / f"{with_trace['id']}.json"))
