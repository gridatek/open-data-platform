# Superset with the Trino SQLAlchemy dialect + the Postgres driver baked in, so
# they're present at start (no `pip install` on every boot — faster, reproducible).
FROM apache/superset:4.1.1

USER root
RUN pip install --no-cache-dir 'trino>=0.330' psycopg2-binary
USER superset
