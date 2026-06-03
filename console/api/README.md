# console/api — Spring Boot

Control-plane API. Java 21, Spring Boot 3.3, Maven. Read-only in Phase 2; Phase 4
adds governance **writes** (edit Ranger policies).

## Endpoints

| Method & path                                | Does                                       |
|----------------------------------------------|--------------------------------------------|
| `GET  /api/services`                         | each service + `UP`/`DOWN` (health probe)  |
| `GET  /api/catalog/namespaces`               | Iceberg namespaces (dotted paths)          |
| `GET  /api/catalog/namespaces/{ns}/tables`   | table names in a namespace                 |
| `GET  /api/policies`                         | Ranger policies on `trino-odp` (with `id`) |
| `POST /api/policies`                         | **create** a policy (raw Ranger JSON body) |
| `PUT  /api/policies/{id}`                    | **replace** a policy                       |
| `POST /api/policies/{id}/enabled`            | **enable/disable** — `{"enabled":bool}`    |
| `POST /api/services/{name}/restart`          | 501 — needs K8s (Phase 4b)                 |
| `POST /api/services/{name}/scale`            | 501 — needs K8s (Phase 4b)                 |
| `GET  /actuator/health`                      | the console's own health                   |

The headline Phase 4 action is `POST /api/policies/{id}/enabled` — toggling the
masking policy from the console flips column masking in Trino.

## Container

```bash
docker build -t odp/console-api .     # multi-stage; or use docker-compose.console.yml
```

## Run / test

```bash
mvn spring-boot:run     # starts on :8090
mvn -B test             # unit + slice tests
```

## Config

Defaults (in `src/main/resources/application.yml`) point at the quickstart on
localhost. Override per environment with env vars, e.g.:

```
ODP_CATALOG_REST_URL=http://iceberg-rest:8181
ODP_RANGER_URL=http://ranger-admin:6080
ODP_HEALTH_TRINO=http://trino:8080/v1/info
```

## Layout

```
src/main/java/com/gridatek/odp/console/
├── ConsoleApplication.java
├── config/      # ConsoleProperties, HttpClientConfig (RestClient), WebConfig (CORS)
├── health/      # /api/services — HTTP health probes
├── catalog/     # /api/catalog/** — Iceberg REST proxy
├── policy/      # /api/policies — Ranger REST proxy (read + write)
└── control/     # /api/services/{name}/** — lifecycle stubs (501, Phase 4b)
```

> Governance writes are live (CORS allows `GET/POST/PUT`). Service lifecycle
> (provision/scale) is stubbed at 501 until the K8s integration lands in Phase 4b.
