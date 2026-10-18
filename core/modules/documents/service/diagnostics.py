"""Diagnóstico local: somente payloads da aplicação, nunca headers ou credenciais."""
import json
import logging
import hashlib
from contextlib import contextmanager
from contextvars import ContextVar
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

from django.conf import settings

logger = logging.getLogger(__name__)
_current = ContextVar("analysis_diagnostic", default=None)


def is_capturing():
    return _current.get() is not None


def record(event, **details):
    trace = _current.get()
    if trace is not None:
        # Congela o estado antes de qualquer correção posterior.
        trace["events"].append(json.loads(json.dumps({
            "event": event, "at": datetime.now(timezone.utc).isoformat(), **details,
        })))


@contextmanager
def capture_analysis(document_id, *, force=False):
    enabled = force or getattr(settings, "AI_DIAGNOSTICS_ENABLED", False)
    trace = {
        "schema_version": 1,
        "id": uuid4().hex, "document_id": document_id,
        "started_at": datetime.now(timezone.utc).isoformat(), "events": [],
        "service_sha256": hashlib.sha256(Path(__file__).with_name("ai_service.py").read_bytes()).hexdigest(),
    } if enabled else None
    token = _current.set(trace)
    failure = None
    try:
        yield trace
    except Exception as exc:
        failure = exc
        record("failure", exception=type(exc).__name__, paths=getattr(exc, "paths", []))
        raise
    finally:
        _current.reset(token)
        if trace is not None:
            trace["outcome"] = "failed" if failure else "validated"
            try:
                directory = Path(settings.AI_DIAGNOSTICS_DIR)
                directory.mkdir(parents=True, exist_ok=True)
                path = directory / f"{trace['id']}.json"
                path.write_text(json.dumps(trace, ensure_ascii=False, indent=2), encoding="utf-8")
                logger.info("Diagnóstico da análise %s: %s", document_id, trace["id"])
                if failure is not None:
                    failure.diagnostic_id = trace["id"]
            except OSError:
                # Falha no diagnóstico nunca deve invalidar uma análise.
                logger.warning("Não foi possível gravar o diagnóstico da análise %s", document_id)
