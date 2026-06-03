# governance — Ranger + Atlas (the SDX clone)

Apache **Ranger** for table/column policies, Apache **Atlas** for lineage. The
differentiator of the whole platform: one policy + lineage model that every
engine obeys. This is Phase 1 — proving a Ranger policy actually masks a column
in a Trino query, on top of the Phase 0 lakehouse.

## What's here

```
governance/
├── ranger/                     # Ranger admin image (policy server + UI)
│   ├── Dockerfile              #   builds from a Ranger admin tarball
│   ├── install.properties      #   templated config (rendered at startup)
│   └── entrypoint.sh           #   render → setup.sh → ranger-admin start
├── trino/                      # Ranger config for the stock Trino image
│   ├── etc/access-control.properties   # access-control.name=ranger
│   └── ranger/                 #   ranger-trino-security / audit / policymgr-ssl .xml
├── policies/                   # Ranger REST payloads
│   ├── trino-service.json      #   registers the "trino-odp" service
│   ├── trino-access.json       #   admin + analyst may SELECT events
│   └── trino-events-mask.json  #   mask `kind` for analyst  ← the proof
└── load-policies.sh            # POST the service + policies to Ranger
```

## Run it (laptop subset)

From `quickstart/`, bring up the lakehouse **and** the governance overlay:

```bash
cd quickstart
cp .env.example .env
docker compose -f docker-compose.yml -f docker-compose.governance.yml up -d --build
```

| Service      | URL                     | Login              |
|--------------|-------------------------|--------------------|
| Ranger admin | http://localhost:6080   | admin / rangerR0cks! |
| Atlas        | http://localhost:21000  | admin / admin      |

Seed data, then load the policies:

```bash
docker compose exec spark spark-submit /home/iceberg/jobs/seed_lakehouse.py
../platform/governance/load-policies.sh
# wait ~30s for the Trino plugin to poll the new policy
```

## The proof — same query, different user

```bash
# admin: sees the real value
docker compose exec trino trino --user admin \
  --execute "SELECT id, kind FROM iceberg.smoke.events ORDER BY id"

# analyst: the `kind` column comes back masked
docker compose exec trino trino --user analyst \
  --execute "SELECT id, kind FROM iceberg.smoke.events ORDER BY id"
```

If `kind` is real for `admin` and masked for `analyst`, Phase 1 is green: one
governed table, one Ranger policy, enforced inside the engine. CI runs exactly
this in `.github/workflows/governance-ci.yml`.

## Versions (pinned)

- **Ranger 2.8.0** — admin installed from the prebuilt tarball at
  `archive.apache.org/dist/ranger/2.8.0/services/admin/ranger-2.8.0-admin.tar.gz`
  (~389 MB; the image build is the heaviest step). 2.5.0+ ships the Trino
  service definition, so the `trino-odp` service uses `type: trino`.
- **Trino 479** — the Ranger access control is **built into Trino since 466**,
  so there is *no* custom Trino image and *no* plugin download. We enable it on
  the stock `trinodb/trino:479` by mounting `access-control.properties` and the
  three `ranger-*.xml` files into `/etc/trino`. (The old Apache `presto-plugin`
  is abandoned — it broke on the `io.prestosql` → `io.trino` rename.)

## ⚠️ Known rough edges (code first, debug later)

Written to iterate against CI, not validated locally:

- **Ranger config coordinates** in `ranger-trino-security.xml` and the
  `ranger.plugin.config.resource` lookup path may still need tuning to where
  Trino 479 actually resolves those resource files.
- **Atlas** uses a community image as a placeholder and is wired for lineage
  later; it isn't part of the masking proof yet.
- **Default-deny:** Ranger denies unless a policy allows, hence the explicit
  `trino-access.json`. Catalog/schema-level grants may still need widening.
