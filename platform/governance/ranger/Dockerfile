# ───────────────────────────────────────────────────────────────
# Apache Ranger Admin — policy server + UI
#
# NOTE: Apache does not publish a Ranger *admin image*, but it does publish a
# prebuilt admin *tarball* per release (services/admin/ranger-<ver>-admin.tar.gz,
# ~389 MB). We install that here. This is the heaviest layer in the project —
# the download + image build is large but reproducible.
# ───────────────────────────────────────────────────────────────
FROM eclipse-temurin:11-jdk-jammy

ARG RANGER_VERSION=2.8.0
# Apache publishes a prebuilt admin binary in the release's services/admin dir.
# Pinned to the permanent archive mirror (downloads.apache.org rotates old releases out).
ARG RANGER_ADMIN_TARBALL_URL=https://archive.apache.org/dist/ranger/${RANGER_VERSION}/services/admin/ranger-${RANGER_VERSION}-admin.tar.gz

ENV RANGER_HOME=/opt/ranger-admin
ENV PATH="${RANGER_HOME}:${PATH}"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        curl ca-certificates python3 postgresql-client bc; \
    rm -rf /var/lib/apt/lists/*

# Pull the JDBC driver Ranger uses to talk to Postgres.
RUN curl -fsSL \
      "https://jdbc.postgresql.org/download/postgresql-42.7.3.jar" \
      -o /usr/share/java/postgresql.jar

# Install the admin distribution.
RUN set -eux; \
    mkdir -p "${RANGER_HOME}"; \
    curl -fsSL "${RANGER_ADMIN_TARBALL_URL}" -o /tmp/ranger-admin.tar.gz; \
    tar -xzf /tmp/ranger-admin.tar.gz --strip-components=1 -C "${RANGER_HOME}"; \
    rm -f /tmp/ranger-admin.tar.gz

# install.properties is rendered at container start from env (see entrypoint).
COPY install.properties "${RANGER_HOME}/install.properties.tmpl"
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 6080
ENTRYPOINT ["/entrypoint.sh"]
