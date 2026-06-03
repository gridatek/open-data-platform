# 02 Data Analyst — Lab 4: Discovery & lineage in Atlas

**Time:** ~20 min · **Prereqs:** Atlas up (`make governance` or `make all`),
`cd quickstart`

## Goal

Find data you didn't create and understand where it came from. An analyst's first
question on a new table is "can I trust this?" — Atlas answers it with search,
metadata, and lineage.

Register the demo lineage graph (idempotent):

```bash
../platform/governance/atlas/register-lineage.sh
```

Open http://localhost:21000 — log in `admin` / `admin`.

## Steps

1. **Search the catalog.** In the top search, type `events`. You'll find the
   `iceberg.smoke.events` dataset entity.

   > **On open-source:** Atlas indexes entities pushed via its REST API.
   > **On real CDP:** Atlas is part of SDX and is populated automatically as
   > engines run — search/discovery is a Data Analyst objective.

2. **Inspect the entity.** Open it — note `qualifiedName`, type, and any
   attributes. This is the metadata an analyst reads before querying.

3. **Open the Lineage tab.** You'll see the graph:

   ```
   events_source ──[seed_lakehouse]──▶ iceberg.smoke.events
   ```

   This tells you the table is produced by the `seed_lakehouse` process from
   `events_source` — provenance you can cite.

   > **On real CDP:** lineage is captured automatically by CDE/CDW jobs; here we
   > register it explicitly, but the graph you read is identical in shape.

4. **(Concept) Classifications & glossary.** Atlas lets admins tag columns
   (e.g. `PII`) and define business glossary terms. Ranger can then mask *by
   classification* — "mask everything tagged PII" — instead of naming columns.

   > **On real CDP:** tag-based masking (Ranger + Atlas classifications) is the
   > advanced governance pattern the platform is built to demonstrate; wiring it
   > end-to-end here is a stretch goal (see the governance README).

## Check yourself

- [ ] Searching `events` returns the table entity (step 1).
- [ ] The Lineage tab shows `events_source` upstream of the table (step 3).

## Going further

- Register a lineage entity for your Lab 1 `orders` table and link it to a
  process, then view its graph.
- You've completed the Data Analyst track — you've queried (Trino), secured
  (Ranger), visualized (Superset), and traced (Atlas) the same governed data.
  That four-tool loop over one table *is* the SDX value proposition.
