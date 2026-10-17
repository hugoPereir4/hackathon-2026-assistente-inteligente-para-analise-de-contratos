import copy
import json
import threading
from types import SimpleNamespace
from unittest.mock import patch

from django.db import close_old_connections, connection
from django.test import override_settings
from google import genai
from google.genai import types
from rest_framework.test import APITransactionTestCase

from core.models import Company, CompanyFact, Document, DocumentAnswerBatch
from core.modules.documents.service.ai_service import build_company_context, calculate_adherence
from core.modules.documents.service.analysis_schema import AnswerInterpretation
from core.modules.documents.service.answer_service import (
    AnswerConflictError, analysis_fingerprint, confirm_answer_batch,
)
from core.test_analysis import TEXT, answer, parse


REAL_GENAI_CLIENT = genai.Client


def interpretation(value=True, *, sufficient=True, kind="booleano", fields=None, question_id="q1"):
    return {"respostas": [{
        "pergunta_id": question_id, "suficiente": sufficient,
        "justificativa": "A resposta explicita a informação solicitada." if sufficient else "Não há confirmação suficiente.",
        "esclarecimento": None if sufficient else "A certificação já foi obtida?",
        "tipo_valor": kind if sufficient else None,
        "valor": value if sufficient else None, "tipos_campos": fields if sufficient else None,
    }]}


def provider_response(payload):
    return SimpleNamespace(text=json.dumps(payload))


@override_settings(GOOGLE_AI_API_KEY="test-key", GOOGLE_AI_MODEL="test-model")
class AnswerFlowTests(APITransactionTestCase):
    def setUp(self):
        self.company = Company.objects.create(
            email="answers@example.com", cnpj="12345678000199", confirmed=True,
        )
        self.document = self.make_document()
        self.client.force_authenticate(self.company)
        patcher = patch("core.modules.documents.service.ai_service.genai.Client")
        self.client_class = patcher.start()
        self.addCleanup(patcher.stop)
        self.generate = self.client_class.return_value.__enter__.return_value.models.generate_content
        self.generate.return_value = provider_response(interpretation())

    def make_document(self, company=None):
        company = company or self.company
        analysis = parse(answer("desconhecido", []))
        adherence, outcome = calculate_adherence(analysis)
        payload = {
            **analysis.model_dump(mode="json"), "schema_version": 2,
            "aderencia": adherence, "outcome": outcome.value,
            "metadados": {"contexto_empresa": build_company_context(company)},
        }
        return Document.objects.create(
            company=company, filename="demo.pdf", file_path="", text_content=TEXT,
            status="ready", analysis_json=payload, score=adherence["score"], outcome=outcome.value,
        )

    def preview(self, answers=None, document=None):
        return self.client.post(
            f"/api/v1/documents/{(document or self.document).pk}/answers/preview/",
            {"respostas": answers if answers is not None else [
                {"pergunta_id": "q1", "texto": "Sim, temos ISO 9001."},
            ]}, format="json",
        )

    def confirm(self, batch_id, approved=None, overwrite=None, document=None, **extra):
        return self.client.post(
            f"/api/v1/documents/{(document or self.document).pk}/answers/{batch_id}/confirm/",
            {"propostas_aprovadas": approved if approved is not None else ["q1"],
             "autorizar_substituicao": overwrite or [], **extra}, format="json",
        )

    def batch(self):
        response = self.preview()
        self.assertEqual(response.status_code, 201, response.data)
        return DocumentAnswerBatch.objects.get(pk=response.data["id"])

    def fact(self, value, confirmed=True):
        return CompanyFact.objects.create(
            company=self.company, fact_key="iso_9001", label="ISO 9001",
            value_json=value, source="user", confirmed=confirmed,
        )

    def test_preview_does_not_write_facts_and_confirmation_reanalyzes(self):
        batch = self.batch()
        self.assertFalse(self.company.facts.exists())
        self.assertEqual(batch.status, "pending")
        self.assertEqual(batch.proposals[0]["valor_proposto"], True)
        self.assertEqual(batch.proposals[0]["texto_original"], "Sim, temos ISO 9001.")
        self.assertIsNone(batch.proposals[0]["valor_anterior"])
        self.assertEqual(batch.analysis_fingerprint, analysis_fingerprint(self.document.analysis_json))
        self.assertEqual(self.generate.call_count, 1)
        self.assertEqual(self.generate.call_args.kwargs["config"].response_json_schema, AnswerInterpretation.model_json_schema())

        def reanalyze(**kwargs):
            self.assertFalse(connection.in_atomic_block)
            inputs = json.loads(kwargs["contents"])
            fact = inputs["contexto_empresa"]["fatos.iso_9001"]
            self.assertEqual((fact["valor"], fact["origem"], fact["confirmado"]), (True, "user", True))
            self.assertEqual(Document.objects.get(pk=self.document.pk).status, "processing")
            return provider_response(answer())

        self.generate.side_effect = reanalyze
        response = self.confirm(batch.pk)
        self.assertEqual(response.status_code, 200, response.data)
        self.assertTrue(response.data["respostas_salvas"])
        self.assertEqual(response.data["reavaliacao"], {"status": "ready", "erro": None})
        result = response.data["documento"]
        self.assertEqual((result["status"], result["score"], result["outcome"]), ("ready", 100, "good_fit"))
        self.assertFalse(result["analysis_desatualizada"])
        self.assertEqual(result["analysis_json"]["perguntas_pendentes"], [])
        batch.refresh_from_db()
        self.assertEqual(batch.status, "confirmed")
        self.assertIsNotNone(batch.confirmed_at)
        self.assertEqual(batch.approved_proposals, ["q1"])

    def test_explicit_negative_is_saved_as_false(self):
        self.generate.return_value = provider_response(interpretation(False))
        batch = self.batch()
        self.generate.return_value = provider_response(answer("nao_atende"))
        response = self.confirm(batch.pk)
        self.assertEqual(response.status_code, 200, response.data)
        self.assertIs(self.company.facts.get().value_json, False)
        self.assertEqual(response.data["documento"]["outcome"], "incompatible")

    def test_uncertain_responses_require_clarification(self):
        for text in ("Não sei", "Estamos buscando a certificação"):
            self.generate.return_value = provider_response(interpretation(sufficient=False))
            response = self.preview([{"pergunta_id": "q1", "texto": text}])
            self.assertEqual(response.status_code, 201, response.data)
            self.assertFalse(response.data["proposals"][0]["suficiente"])
            confirmation = self.confirm(response.data["id"])
            self.assertEqual(confirmation.status_code, 400)
            self.assertFalse(self.company.facts.exists())
            self.document.refresh_from_db()
            self.assertEqual(self.document.status, "ready")

    def test_confirmed_conflict_requires_separate_authorization(self):
        self.fact(False)
        batch = self.batch()
        self.assertTrue(batch.proposals[0]["exige_autorizacao_substituicao"])
        self.assertIs(batch.proposals[0]["valor_anterior"]["valor"], False)
        response = self.confirm(batch.pk)
        self.assertEqual(response.status_code, 409)
        self.assertIs(self.company.facts.get().value_json, False)
        self.document.refresh_from_db()
        self.assertEqual(self.document.status, "ready")
        batch.refresh_from_db()
        self.assertEqual(batch.status, "pending")
        self.generate.return_value = provider_response(answer())
        response = self.confirm(batch.pk, overwrite=["q1"])
        self.assertEqual(response.status_code, 200, response.data)
        self.assertIs(self.company.facts.get().value_json, True)
        batch.refresh_from_db()
        self.assertEqual(batch.overwrite_authorizations, ["q1"])

    def test_unconfirmed_fact_does_not_require_overwrite_authorization(self):
        fact = self.fact(False, confirmed=False)
        fact.source = "ai"
        fact.save()
        batch = self.batch()
        self.assertFalse(batch.proposals[0]["exige_autorizacao_substituicao"])
        self.generate.return_value = provider_response(answer())
        self.assertEqual(self.confirm(batch.pk).status_code, 200)
        fact.refresh_from_db()
        self.assertEqual((fact.value_json, fact.confirmed, fact.source), (True, True, "user"))

    def test_confirmation_is_idempotent_and_uses_saved_values_only(self):
        batch = self.batch()
        self.generate.return_value = provider_response(answer())
        response = self.confirm(batch.pk, valor_proposto=False, company=999)
        self.assertEqual(response.status_code, 200)
        self.assertIs(self.company.facts.get().value_json, True)
        calls = self.generate.call_count
        response = self.confirm(batch.pk)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(self.generate.call_count, calls)
        self.assertEqual(self.company.facts.count(), 1)

    def test_reanalysis_failure_preserves_facts_and_old_analysis_then_can_retry(self):
        original = copy.deepcopy(self.document.analysis_json)
        batch = self.batch()
        self.generate.side_effect = TimeoutError("private details")
        response = self.confirm(batch.pk)
        self.assertEqual(response.status_code, 200, response.data)
        self.assertTrue(response.data["respostas_salvas"])
        self.assertEqual(response.data["reavaliacao"]["status"], "failed")
        self.assertNotIn("private details", response.data["reavaliacao"]["erro"])
        self.assertIs(self.company.facts.get().value_json, True)
        document = response.data["documento"]
        self.assertEqual(document["analysis_json"], original)
        self.assertEqual(document["status"], "failed")
        self.assertTrue(document["analysis_desatualizada"])
        calls = self.generate.call_count
        self.assertEqual(self.confirm(batch.pk).status_code, 200)
        self.assertEqual(self.generate.call_count, calls)
        self.generate.side_effect = None
        self.generate.return_value = provider_response(answer())
        response = self.client.post(f"/api/v1/documents/{self.document.pk}/reanalyze/")
        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(response.data["status"], "ready")
        self.assertFalse(response.data["analysis_desatualizada"])

    def test_changes_to_analysis_or_facts_reject_stale_proposal(self):
        batch = self.batch()
        self.fact(False)
        self.assertEqual(self.confirm(batch.pk).status_code, 409)
        self.assertIs(self.company.facts.get().value_json, False)
        self.company.facts.all().delete()
        self.document.analysis_json["resumo"] = "Nova análise"
        self.document.save(update_fields=["analysis_json"])
        self.assertEqual(self.confirm(batch.pk).status_code, 409)
        self.assertFalse(self.company.facts.exists())

    def test_other_documents_become_stale_without_automatic_calls(self):
        other = self.make_document()
        batch = self.batch()
        self.generate.return_value = provider_response(answer())
        self.assertEqual(self.confirm(batch.pk).status_code, 200)
        response = self.client.get(f"/api/v1/documents/{other.pk}/")
        self.assertTrue(response.data["analysis_desatualizada"])
        self.assertEqual(response.data["status"], "ready")
        self.assertEqual(self.generate.call_count, 2)

    def test_legacy_analysis_is_readable_but_requires_upgrade_for_answers(self):
        self.document.analysis_json["schema_version"] = 1
        self.document.analysis_json["perguntas_pendentes"][0].pop("destino")
        self.document.save(update_fields=["analysis_json"])
        self.assertEqual(self.preview().status_code, 409)
        self.assertEqual(self.client.get(f"/api/v1/documents/{self.document.pk}/").status_code, 200)
        self.generate.return_value = provider_response(answer("desconhecido", []))
        response = self.client.post(f"/api/v1/documents/{self.document.pk}/reanalyze/")
        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(response.data["analysis_json"]["schema_version"], 2)

    def test_unknown_duplicate_empty_and_non_profile_questions_are_rejected(self):
        for answers in (
            [], [{"pergunta_id": "missing", "texto": "Sim"}],
            [{"pergunta_id": "q1", "texto": "Sim"}] * 2,
            [{"pergunta_id": "q1", "texto": " "}],
        ):
            self.assertEqual(self.preview(answers).status_code, 400)
        for destination in ("cadastro", "papel"):
            self.document.analysis_json["perguntas_pendentes"][0]["destino"] = destination
            self.document.save(update_fields=["analysis_json"])
            self.assertEqual(self.preview().status_code, 400)
        self.generate.assert_not_called()

    def test_other_company_cannot_preview_confirm_or_reanalyze(self):
        batch = self.batch()
        other = Company.objects.create(email="other@example.com", cnpj="98765432000198")
        doc = self.make_document(other)
        for path in ("answers/preview", f"answers/{batch.pk}/confirm", "reanalyze"):
            response = self.client.post(f"/api/v1/documents/{doc.pk}/{path}/", {}, format="json")
            self.assertEqual(response.status_code, 404)
        response = self.confirm(batch.pk, document=self.make_document())
        self.assertEqual(response.status_code, 404)
        self.assertEqual(self.confirm("invalid-uuid").status_code, 404)

    def test_malformed_interpretations_are_rejected_without_saving_batch(self):
        variants = []
        payload = interpretation()
        payload["respostas"] *= 2
        variants.append(payload)
        variants.append(interpretation(question_id="missing"))
        variants.append(interpretation(value=1.1, kind="decimal"))
        payload = interpretation(sufficient=False)
        payload["respostas"][0]["valor"] = False
        variants.append(payload)
        variants.append(interpretation(value="true"))
        variants.append(interpretation(value=1, kind="inteiro"))
        for payload in variants:
            self.generate.return_value = provider_response(payload)
            response = self.preview()
            self.assertEqual(response.status_code, 502, response.data)
        self.assertFalse(DocumentAnswerBatch.objects.exists())
        self.assertFalse(self.company.facts.exists())

    def test_preview_provider_failure_keeps_ready_and_does_not_create_batch(self):
        self.generate.side_effect = TimeoutError("secret")
        self.assertEqual(self.preview().status_code, 502)
        self.document.refresh_from_db()
        self.assertEqual(self.document.status, "ready")
        self.assertFalse(DocumentAnswerBatch.objects.exists())

    def test_preserves_existing_object_and_decimal_precision(self):
        previous = {"ano": 2025, "moeda": "BRL", "valor": "1200000.00"}
        CompanyFact.objects.create(
            company=self.company, fact_key="annual_revenue", label="Receita",
            value_json=previous, confirmed=False,
        )
        question = self.document.analysis_json["perguntas_pendentes"][0]
        question.update(fato_chave="annual_revenue", fato_rotulo="Receita", tipo_valor="objeto")
        self.document.save(update_fields=["analysis_json"])
        proposed = {**previous, "valor": "1234567890123456789.90"}
        self.generate.return_value = provider_response(interpretation(
            value=proposed, kind="objeto", fields={"ano": "inteiro", "moeda": "texto", "valor": "decimal"},
        ))
        batch = self.batch()
        self.assertEqual(batch.proposals[0]["valor_proposto"], proposed)
        self.generate.return_value = provider_response(answer("desconhecido", []))
        response = self.confirm(batch.pk)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(self.company.facts.get().value_json, proposed)

    def test_new_scalar_types_and_invalid_dates_or_decimals(self):
        for kind, value in (
            ("inteiro", 12), ("decimal", "1234567890123456789.90"),
            ("texto", "Equipe de suporte dedicada"), ("data", "2026-10-17"),
        ):
            with self.subTest(kind=kind):
                self.document.analysis_json["perguntas_pendentes"][0]["tipo_valor"] = kind
                self.document.save(update_fields=["analysis_json"])
                self.generate.return_value = provider_response(interpretation(value, kind=kind))
                batch = self.batch()
                self.assertEqual(batch.proposals[0]["valor_proposto"], value)
        for kind, value in (("data", "2026-02-30"), ("data", "20261017"), ("decimal", "1.234,50")):
            self.document.analysis_json["perguntas_pendentes"][0]["tipo_valor"] = kind
            self.document.save(update_fields=["analysis_json"])
            self.generate.return_value = provider_response(interpretation(value, kind=kind))
            self.assertEqual(self.preview().status_code, 502)

    def test_cannot_change_existing_structure(self):
        self.fact({"possui": True})
        self.assertEqual(self.preview().status_code, 502)
        self.assertEqual(self.company.facts.get().value_json, {"possui": True})

    def test_changes_while_interpreting_reject_preview(self):
        def change_profile(**kwargs):
            self.fact(False)
            return provider_response(interpretation())

        self.generate.side_effect = change_profile
        self.assertEqual(self.preview().status_code, 409)
        self.assertFalse(DocumentAnswerBatch.objects.exists())

    def test_atomic_batch_conflict_rolls_back_all_selected_facts(self):
        self.fact(False)
        payload = self.document.analysis_json
        second = copy.deepcopy(payload["perguntas_pendentes"][0])
        second.update(id="q2", fato_chave="iso_27001", fato_rotulo="ISO 27001")
        payload["perguntas_pendentes"].append(second)
        self.document.save(update_fields=["analysis_json"])
        parsed = interpretation()
        parsed["respostas"] += interpretation(question_id="q2")["respostas"]
        self.generate.return_value = provider_response(parsed)
        response = self.preview([
            {"pergunta_id": "q1", "texto": "Sim"}, {"pergunta_id": "q2", "texto": "Sim"},
        ])
        self.assertEqual(response.status_code, 201, response.data)
        response = self.confirm(response.data["id"], approved=["q2", "q1"])
        self.assertEqual(response.status_code, 409)
        self.assertFalse(self.company.facts.filter(fact_key="iso_27001").exists())
        self.assertIs(self.company.facts.get().value_json, False)

    def test_partial_answers_and_partial_approval_are_allowed(self):
        second = copy.deepcopy(self.document.analysis_json["perguntas_pendentes"][0])
        second.update(id="q2", fato_chave="iso_27001", fato_rotulo="ISO 27001")
        self.document.analysis_json["perguntas_pendentes"].append(second)
        self.document.save(update_fields=["analysis_json"])
        partial = self.preview()
        self.assertEqual(partial.status_code, 201)
        parsed = interpretation()
        parsed["respostas"] += interpretation(question_id="q2")["respostas"]
        self.generate.return_value = provider_response(parsed)
        response = self.preview([
            {"pergunta_id": "q1", "texto": "Sim"}, {"pergunta_id": "q2", "texto": "Sim"},
        ])
        self.assertEqual(response.status_code, 201)
        self.generate.return_value = provider_response(answer())
        self.assertEqual(self.confirm(response.data["id"], approved=["q1"]).status_code, 200)
        self.assertEqual(list(self.company.facts.values_list("fact_key", flat=True)), ["iso_9001"])

    def test_real_sdk_serializes_interpretation_schema_with_mock_http(self):
        self.client_class.side_effect = REAL_GENAI_CLIENT
        payload = {"candidates": [{
            "content": {"role": "model", "parts": [{"text": json.dumps(interpretation())}]},
            "finishReason": "STOP",
        }]}
        with patch(
            "google.genai._api_client.BaseApiClient.request",
            return_value=types.HttpResponse(body=json.dumps(payload), headers={}),
        ) as request:
            response = self.preview()
        self.assertEqual(response.status_code, 201, response.data)
        request.assert_called_once()
        generation = request.call_args.args[2]["generationConfig"]
        self.assertEqual(generation["responseJsonSchema"], AnswerInterpretation.model_json_schema())
        self.assertNotIn("responseSchema", generation)

    def test_concurrent_confirmation_does_not_duplicate_generation_or_overwrite_new_fact(self):
        batch = self.batch()
        other_doc = self.make_document()
        response = self.preview(document=other_doc)
        self.assertEqual(response.status_code, 201)
        other_batch = DocumentAnswerBatch.objects.get(pk=response.data["id"])
        entered, release = threading.Event(), threading.Event()
        failures = []

        def wait_for_other_request(**kwargs):
            self.assertFalse(connection.in_atomic_block)
            entered.set()
            if not release.wait(5):
                raise TimeoutError("test synchronization timeout")
            return provider_response(answer())

        def first_request():
            close_old_connections()
            try:
                confirm_answer_batch(
                    Document.objects.get(pk=self.document.pk),
                    DocumentAnswerBatch.objects.get(pk=batch.pk), ["q1"], [],
                )
            except Exception as exc:
                failures.append(exc)
            finally:
                close_old_connections()

        self.generate.side_effect = wait_for_other_request
        thread = threading.Thread(target=first_request)
        thread.start()
        try:
            self.assertTrue(entered.wait(5))
            repeated = confirm_answer_batch(self.document, batch, ["q1"], [])
            self.assertEqual(repeated.status, "confirmed")
            self.assertEqual(repeated.reanalysis_status, "processing")
            with self.assertRaises(AnswerConflictError):
                confirm_answer_batch(other_doc, other_batch, ["q1"], [])
            other_doc.refresh_from_db()
            self.assertEqual(other_doc.status, "ready")
            self.assertEqual(self.company.facts.count(), 1)
            self.assertEqual(self.generate.call_count, 3)  # Duas prévias e uma reavaliação.
        finally:
            release.set()
            thread.join(5)
        self.assertFalse(thread.is_alive())
        self.assertEqual(failures, [])
        self.document.refresh_from_db()
        self.assertEqual(self.document.status, "ready")
