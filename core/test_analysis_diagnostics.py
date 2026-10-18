import json
from io import StringIO
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

from django.core.management import call_command
from django.test import SimpleTestCase, override_settings

from core.modules.documents.service.ai_service import EvidenceValidationError
from core.modules.documents.service.diagnostics import capture_analysis, record
from core.modules.documents.view import DocumentViewSet


@override_settings(DEBUG=True, AI_DIAGNOSTICS_ENABLED=True, GOOGLE_AI_API_KEY="secret-sentinel")
class AnalysisDiagnosticsTests(SimpleTestCase):
    def setUp(self):
        self.directory = TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.settings_override = override_settings(AI_DIAGNOSTICS_DIR=Path(self.directory.name))
        self.settings_override.enable()
        self.addCleanup(self.settings_override.disable)

    def test_capture_freezes_data_and_correlates_failure_without_credentials(self):
        data = {"trecho": "Original"}
        error = EvidenceValidationError(["requisitos[0].evidencia"])
        with self.assertRaises(EvidenceValidationError):
            with capture_analysis(4) as trace:
                record("input", data=data)
                data["trecho"] = "Alterado"
                raise error
        path = Path(self.directory.name) / f"{error.diagnostic_id}.json"
        saved = path.read_text(encoding="utf-8")
        payload = json.loads(saved)
        self.assertEqual(payload["outcome"], "failed")
        self.assertEqual(payload["events"][0]["data"]["trecho"], "Original")
        self.assertEqual(payload["id"], trace["id"])
        self.assertNotIn("secret-sentinel", saved)
        response = DocumentViewSet._error_payload(error)
        self.assertEqual(response["diagnostic_id"], trace["id"])
        self.assertIn(trace["id"], response["error"])

    @override_settings(DEBUG=False, AI_DIAGNOSTICS_ENABLED=False)
    def test_automatic_capture_can_be_disabled(self):
        with capture_analysis(4) as trace:
            record("input", text="privado")
        self.assertIsNone(trace)
        self.assertEqual(list(Path(self.directory.name).iterdir()), [])

    def test_storage_failure_does_not_replace_analysis_error(self):
        error = EvidenceValidationError(["requisitos[0].evidencia"])
        with patch.object(Path, "write_text", side_effect=OSError("disk full")):
            with self.assertLogs("core.modules.documents.service.diagnostics", level="WARNING"):
                with self.assertRaises(EvidenceValidationError) as raised:
                    with capture_analysis(4):
                        raise error
        self.assertIs(raised.exception, error)
        self.assertFalse(hasattr(error, "diagnostic_id"))

    def test_offline_replay_detects_captured_path_mismatch_without_provider(self):
        path = Path(self.directory.name) / "captured.json"
        path.write_text(json.dumps({"events": [
            {"event": "provider_request", "schema": {"title": "EvidenceCorrections"},
             "data": {"itens": [{"caminho": "requisitos[0].evidencia"}]}},
            {"event": "provider_response", "text": json.dumps({"correcoes": [
                {"caminho": "requisitos[0].evidencia.trecho", "trecho": "Texto\\noriginal"},
            ]})},
        ]}), encoding="utf-8")
        output = StringIO()
        with patch("core.modules.documents.service.ai_service.genai.Client") as provider:
            call_command("debug_analysis", replay=path, stdout=output)
        provider.assert_not_called()
        self.assertIn("caminhos divergentes", output.getvalue())
        self.assertIn("requisitos[0].evidencia.trecho", output.getvalue())
