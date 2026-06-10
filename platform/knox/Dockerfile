# ───────────────────────────────────────────────────────────────
# Apache Knox Gateway — the perimeter for the platform (≈ CDP Knox).
#
# Knox is the single HTTPS entry point that reverse-proxies every service
# behind one host:port, authenticating at the edge. Apache publishes a
# prebuilt gateway tarball per release; we install that (same approach as
# the Ranger image, which builds from Apache's admin tarball).
# ───────────────────────────────────────────────────────────────
FROM eclipse-temurin:11-jdk-jammy

ARG KNOX_VERSION=2.0.0
# Pinned to the permanent archive mirror (downloads.apache.org rotates old releases out).
ARG KNOX_TARBALL_URL=https://archive.apache.org/dist/knox/${KNOX_VERSION}/knox-${KNOX_VERSION}.tar.gz

ENV GATEWAY_HOME=/opt/knox
ENV PATH="${GATEWAY_HOME}/bin:${PATH}"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl ca-certificates; \
    rm -rf /var/lib/apt/lists/*

# Install the gateway distribution.
RUN set -eux; \
    mkdir -p "${GATEWAY_HOME}"; \
    curl -fsSL "${KNOX_TARBALL_URL}" -o /tmp/knox.tar.gz; \
    tar -xzf /tmp/knox.tar.gz --strip-components=1 -C "${GATEWAY_HOME}"; \
    rm -f /tmp/knox.tar.gz

# Custom service definitions (Trino, MLflow, Iceberg REST, MinIO, Jupyter, …)
# for backends Knox does not ship a built-in definition for. Each is a simple
# reverse-proxy passthrough — see services/README in the repo.
COPY services/ ${GATEWAY_HOME}/data/services/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Knox refuses to run as root; give it an unprivileged owner of its home.
RUN useradd -r -m -d /home/knox knox \
    && chown -R knox:knox "${GATEWAY_HOME}"
USER knox

# 8443 = gateway (HTTPS) ; 33389 = bundled demo LDAP (ApacheDS)
EXPOSE 8443 33389
ENTRYPOINT ["/entrypoint.sh"]
