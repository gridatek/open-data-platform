# 03 Administrator — Lab 4: Audit trails & access review

**Time:** ~20 min · **Prereqs:** `make console`, `make seed`, `cd quickstart`

## Goal

Answer the two questions every auditor asks: **"who accessed this?"** (audit
trail) and **"who *can* access this?"** (access review). You'll see what Ranger
audits capture, why they're off in the laptop subset, and how to do an access
review with what you have.

## Steps

1. **Understand what Ranger audits are.** For *every* access decision Ranger
   records: the user, the resource (catalog/schema/table/column), the access type,
   allowed-or-denied, and which policy decided. That stream is the audit trail an
   admin reviews and exports.

   > **On real CDP:** the Ranger **Audit** tab is a tested objective — filtering
   > access events by user/resource/result.

2. **Note the laptop-subset limitation.** Audits need a sink (Solr/Elasticsearch),
   which we don't run here, so auditing is **disabled**:

   - `platform/governance/trino/ranger/ranger-trino-audit.xml` →
     `xasecure.audit.is.enabled = false`
   - `platform/governance/ranger/install.properties` → `audit_store` empty

   > **On real CDP:** audits are always on, backed by Solr + HDFS/S3. Enabling
   > them here means adding a Solr service and flipping those two settings.

3. **Use an observable proxy — the engine's own logs.** Run a query, then look at
   what Trino logged:

   ```bash
   docker compose exec trino trino --user analyst \
     --execute "SELECT id, kind FROM iceberg.smoke.events" >/dev/null
   docker compose logs --tail=30 trino
   ```

   You can see query activity even without the Ranger audit sink.

4. **Do an access review** — "who can see `iceberg.smoke.events.kind`?" Read the
   policies that govern it:

   ```bash
   curl -s http://localhost:8090/api/policies | jq '.[] | {name, type, enabled}'
   ```

   Cross-reference in Ranger Admin (http://localhost:6080 → `trino-odp`): the
   **Access** policy says who may `select`; the **Masking** policy says `analyst`
   sees `kind` masked. Together they answer the review.

   > **On real CDP:** access review = reading the effective policies on a resource
   > plus the audit history. Same workflow, with live audits attached.

## Check yourself

- [ ] You can explain what a Ranger audit event contains (step 1).
- [ ] You found where auditing is disabled in the repo (step 2).
- [ ] `/api/policies` + Ranger Admin together tell you who can see `kind` (step 4).

## Going further

- Stretch: add a Solr container, set `xasecure.audit.is.enabled=true`, and watch
  the Ranger **Audit** tab populate as you run Trino queries.
- You've completed the Administrator track: monitor health, administer policies,
  manage lifecycle, and review access — the operator's loop over the platform.
