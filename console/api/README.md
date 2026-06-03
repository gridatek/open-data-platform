# console/api — Spring Boot

Read-only control-plane API (Phase 2). Java 21, Spring Boot 3.3, Maven.

## Endpoints

| Method & path                              | Returns                                   |
|--------------------------------------------|-------------------------------------------|
| `GET /api/services`                        | each service + `UP`/`DOWN` (health probe) |
| `GET /api/catalog/namespaces`              | Iceberg namespaces (dotted paths)         |
| `GET /api/catalog/namespaces/{ns}/tables`  | table names in a namespace                |
| `GET /api/policies`                        | Ranger policies on `trino-odp`            |
| `GET /actuator/health`                     | the console's own health                  |

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
└── policy/      # /api/policies — Ranger REST proxy
```

> Read-only by design: CORS allows `GET` only, and there are no write paths.
> Provisioning + policy editing arrive in Phase 4.
