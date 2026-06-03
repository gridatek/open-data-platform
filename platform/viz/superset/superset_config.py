"""Superset config for the Open Data Platform laptop subset.

Minimal single-process setup: SQLite metadata DB, CSRF off so the REST API is
easy to drive from scripts/CI. Not for anything beyond local/dev use.
"""
import os

SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY", "odp-dev-secret-change-me")

# Superset's own metadata DB (not the lakehouse). SQLite is fine single-process.
SQLALCHEMY_DATABASE_URI = "sqlite:////app/superset_home/superset.db"

# SQL Lab runs each query in a worker thread, but SQLite connections are bound to
# the thread that created them by default — which makes Superset's reads of its
# own metadata (the `dbs` table) blow up with "SQLite objects created in a thread
# can only be used in that same thread". Allow the connection to cross threads.
SQLALCHEMY_ENGINE_OPTIONS = {
    "connect_args": {"check_same_thread": False},
}

# Dev conveniences: let scripts/CI hit the API without CSRF dance.
WTF_CSRF_ENABLED = False
TALISMAN_ENABLED = False

FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
}

# Allow longer SQL Lab queries against Trino.
SUPERSET_WEBSERVER_TIMEOUT = 120
SQLLAB_TIMEOUT = 120
