# Superset with the Trino SQLAlchemy dialect baked in, so it's present at start
# (no `pip install` on every boot — faster cold start, reproducible).
FROM apache/superset:4.1.1

USER root
RUN pip install --no-cache-dir 'trino>=0.330'
USER superset
