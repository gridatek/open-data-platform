# console — control plane (≈ Cloudera Manager)

The management console: a **Spring Boot API** + **Angular/Tailwind UI** over the
platform's backing services. Phase 2 was the **read-only MVP**; Phase 4 makes it
a **control plane** — it can edit governance (enable/disable Ranger policies) and,
on Kubernetes, restart/scale services via the API (an RBAC'd ServiceAccount; the
docker-compose subset returns 501 since there's no cluster).

```
console/
├── api/   # Spring Boot — probes service health, proxies Iceberg catalog + Ranger policies
└── web/   # Angular 18 + Tailwind — a dashboard over those endpoints
```

## What it shows (Phase 2)

| Panel        | Source                                   | API endpoint                          |
|--------------|------------------------------------------|---------------------------------------|
| Services     | HTTP health probe of each service        | `GET /api/services`                   |
| Catalog      | Iceberg REST catalog                      | `GET /api/catalog/namespaces`         |
| Governance   | Ranger policies on the `trino-odp` service| `GET /api/policies`                   |

> In the full vision the Services panel reads the **K8s API**; in the laptop
> subset there is no K8s, so "is it up?" is a fast HTTP health probe. The shape
> of the API stays the same when K8s is added later.

## Run (against the quickstart)

Bring up the lakehouse (+ governance) from `quickstart/`, then:

```bash
# 1. API on :8090
cd console/api && mvn spring-boot:run

# 2. Web on :4200 (proxies /api → :8090)
cd console/web && npm install && npm start
```

Open http://localhost:4200. Endpoints default to the quickstart on localhost and
are overridable by env (see `api/src/main/resources/application.yml`).

CI builds and tests both halves in `.github/workflows/console-ci.yml`.
