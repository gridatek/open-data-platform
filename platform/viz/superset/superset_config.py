"""Superset config for the Open Data Platform.

Metadata in Postgres (the `superset-db` service / the umbrella's superset-db),
CSRF on. Talisman (HTTPS/CSP headers) stays off since the laptop subset is plain
HTTP. Not hardened beyond that (no Redis cache / Celery worker).
"""
import os

SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY", "odp-dev-secret-change-me")

# Superset's own metadata DB (not the lakehouse). Postgres — production-shaped,
# and thread-safe (unlike SQLite, which choked SQL Lab's worker threads).
SQLALCHEMY_DATABASE_URI = os.environ.get(
    "SUPERSET_DATABASE_URI",
    "postgresql://superset:superset@superset-db:5432/superset",
)

# CSRF protection on (real-deployment default). Talisman off: the laptop subset
# serves plain HTTP, so HTTPS-enforcing headers would break it.
WTF_CSRF_ENABLED = True
TALISMAN_ENABLED = False

FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
}

# Allow longer SQL Lab queries against Trino.
SUPERSET_WEBSERVER_TIMEOUT = 120
SQLLAB_TIMEOUT = 120
