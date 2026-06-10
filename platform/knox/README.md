# Apache Knox — the platform perimeter (≈ CDP Knox)

Knox is the single HTTPS entry point in front of every service on the `odp`
network. It authenticates at the edge (a demo LDAP for the laptop) and
reverse-proxies each backend under one host:port, exactly the role Knox plays
in a real Cloudera cluster. Fine-grained authorization still lives in Ranger —
**perimeter vs. policy**, the same split as CDP.

> Scope: this is the **gateway-proxy** setup. KnoxSSO (the WebSSO front door
> that Ranger's `install.properties` `sso_providerurl` hook points at) is not
> wired up here — see "Upgrading to KnoxSSO" below.

## Run it

Knox is an overlay; layer it onto whatever you're running. For the whole
platform, `make all` already includes it. For just the lakehouse + Knox:

```bash
make knox
# or, composing overlays by hand:
docker compose --project-directory quickstart \
  -f quickstart/docker-compose.yml \
  -f quickstart/docker-compose.governance.yml \
  -f quickstart/docker-compose.services.yml \
  -f quickstart/docker-compose.console.yml \
  -f quickstart/docker-compose.knox.yml \
  up -d --build
```

Then open the landing page (self-signed TLS → accept the browser warning):

```
https://localhost:8443/gateway/homepage/home
```

**Demo logins** (bundled ApacheDS LDAP): `admin / admin-password`,
`guest / guest-password`. Every proxied service is reachable as
`https://localhost:8443/gateway/odp/<service>/…`, e.g.:

| Service | Through Knox |
|---|---|
| Trino   | `…/gateway/odp/trino/ui/` |
| Ranger  | `…/gateway/odp/ranger/` |
| Atlas   | `…/gateway/odp/atlas/` |
| Superset| `…/gateway/odp/superset/` |
| Airflow | `…/gateway/odp/airflow/home` |
| MLflow  | `…/gateway/odp/mlflow/` |
| NiFi    | `…/gateway/odp/nifi/nifi/` |
| Jupyter | `…/gateway/odp/jupyter/` |
| Hue     | `…/gateway/odp/hue/` |
| MinIO   | `…/gateway/odp/minio/` |
| Iceberg REST | `…/gateway/odp/iceberg/v1/config` |
| Console | `…/gateway/odp/console/api/services` |

The backends keep their own direct ports too — Knox is **additive**, not a
replacement.

## How it's built

Apache doesn't publish an official Knox image, so (like the Ranger image) we
install Apache's released gateway tarball over `eclipse-temurin:11`:

- **`Dockerfile`** — installs Knox 2.0.0, copies in the custom service
  definitions, and runs as an unprivileged `knox` user (the gateway refuses to
  run as root).
- **`entrypoint.sh`** — sets the master secret, **pre-generates the gateway TLS
  keystore with `keytool`** (Knox 2.0.0's own self-signed cert generation hits a
  PKCS12 NPE on recent JDK 11 builds), starts the demo LDAP, drops the shipped
  `sandbox.xml` demo topology, then starts the gateway in the foreground.
- **`topology/odp.xml`** — the live wiring: the auth provider + one `<service>`
  per backend (pointing at its in-network hostname). Edit it and Knox redeploys
  on the fly.
- **`topology/homepage.xml`** — replaces Knox's shipped homepage (which sits
  behind KnoxSSO) with one using the same basic-auth, so the landing page works
  without SSO.
- **`services/<name>/1.0.0/`** — custom reverse-proxy service definitions for
  the backends Knox has no built-in for (Trino, Superset, MLflow, Iceberg REST,
  MinIO, Jupyter, Hue, the console). See [`services/README.md`](services/README.md).

## Caveats (laptop reality)

- **TLS is self-signed** → browser warnings locally. Fine for learning.
- **API/SQL backends proxy cleanly** (Trino, Iceberg REST, MLflow, the Ranger
  REST API). **UI-heavy backends** (Superset, Airflow, NiFi, Jupyter, the Atlas
  UI) emit absolute URLs / websockets that a plain passthrough doesn't rewrite,
  so deep links inside those UIs may break. Fixing each is a matter of adding
  response-rewrite rules to that service's `rewrite.xml` — added incrementally
  so one tricky UI never blocks the rest.
- **Knox does not replace Ranger.** It authenticates the edge; Ranger still
  enforces table/column policies and masking.

## Upgrading to KnoxSSO

To make this faithful to a real CDP setup, turn the `knoxsso.xml` topology
(shipped, already deployed) into the WebSSO provider and flip Ranger's
`platform/governance/ranger/install.properties`:

```properties
sso_enabled=true
sso_providerurl=https://knox:8443/gateway/knoxsso/api/v1/websso
```

Then point the `odp` topology's services at an `SSOCookieProvider` instead of
`ShiroProvider`. That's a deliberate next step, not part of this gateway-proxy
scope.
