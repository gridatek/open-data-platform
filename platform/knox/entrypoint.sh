#!/usr/bin/env bash
# Initialise the master secret, start the bundled demo LDAP (laptop identity
# store) and the gateway, then tail the log so the container stays in the
# foreground and forwards signals for a clean shutdown.
set -euo pipefail

# Must be >= 6 chars: it doubles as the keystore password (keytool minimum).
: "${GATEWAY_HOME:=/opt/knox}"
: "${KNOX_MASTER_SECRET:=knoxsecret}"
: "${KNOX_DEMO_LDAP:=true}"

cd "${GATEWAY_HOME}"

# Master secret protects the gateway keystore. --force makes the image
# restart-safe (re-running is a no-op if it already exists).
echo "[knox] creating master secret"
bin/knoxcli.sh create-master --master "${KNOX_MASTER_SECRET}" --force

# Pre-generate the gateway TLS identity. Knox 2.0.0's own self-signed cert
# generation hits a PKCS12 NPE on recent JDK 11 builds (a JDK regression), so
# we create the keystore ourselves with keytool. Skip if it already exists so
# restarts are idempotent. The keystore password is the master secret.
KEYSTORE="${GATEWAY_HOME}/data/security/keystores/gateway.jks"
if [ ! -f "${KEYSTORE}" ]; then
  echo "[knox] generating gateway TLS identity"
  mkdir -p "$(dirname "${KEYSTORE}")"
  keytool -genkeypair -alias gateway-identity \
    -keyalg RSA -keysize 2048 -validity 3650 \
    -keystore "${KEYSTORE}" -storetype JKS \
    -storepass "${KNOX_MASTER_SECRET}" -keypass "${KNOX_MASTER_SECRET}" \
    -dname "CN=knox,OU=odp,O=odp,L=local,ST=local,C=US"
fi

# Drop Knox's shipped demo topology — it advertises a dozen dead Hadoop
# endpoints (WebHDFS, Hive, Hue, Druid, Oozie…) that would clutter the homepage.
rm -f "${GATEWAY_HOME}/conf/topologies/sandbox.xml"

shutdown() {
  echo "[knox] stopping"
  bin/gateway.sh stop || true
  [ "${KNOX_DEMO_LDAP}" = "true" ] && bin/ldap.sh stop || true
  exit 0
}
trap shutdown SIGTERM SIGINT

if [ "${KNOX_DEMO_LDAP}" = "true" ]; then
  echo "[knox] starting bundled demo LDAP on :33389"
  # Demo users live in conf/users.ldif (admin / guest / sam / tom,
  # each with password "<user>-password").
  bin/ldap.sh start
fi

echo "[knox] starting gateway on :8443"
bin/gateway.sh start

# gateway.sh daemonises; follow the log so docker sees a foreground process.
echo "[knox] gateway up — tailing logs/gateway.log"
sleep 2
exec tail -F logs/gateway.log
