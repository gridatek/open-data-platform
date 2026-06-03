# 02 Data Analyst — Lab 2: Column masking with Ranger

**Time:** ~20 min · **Prereqs:** governance up (`make governance`), `make seed`,
`cd quickstart`

## Goal

See tabular security from the analyst's seat: the *same* query returns different
data depending on who you are, because a Ranger policy masks a column — enforced
inside the engine, not bolted on after.

Load the demo policies first (idempotent):

```bash
../platform/governance/load-policies.sh
sleep 30   # let Trino's Ranger plugin poll the policy
```

## Steps

1. **Query as an admin** — full visibility:

   ```bash
   docker compose exec trino trino --user admin \
     --execute "SELECT id, kind FROM iceberg.smoke.events ORDER BY id"
   ```

   You see real values: `click`, `view`, `purchase`.

2. **Run the identical query as `analyst`:**

   ```bash
   docker compose exec trino trino --user analyst \
     --execute "SELECT id, kind FROM iceberg.smoke.events ORDER BY id"
   ```

   The `kind` column comes back masked. Same SQL, same table — different result,
   because the `mask-events-kind-for-analyst` policy applies to you.

   > **On open-source:** Ranger's `MASK` data-mask type is enforced by the Trino
   > Ranger plugin as the query runs.
   > **On real CDP:** the identical policy masks the column in CDW for the same
   > user. Column masking is an explicit Data Analyst exam objective.

3. **Understand the mask types.** Ranger ships several; the policy chooses one per
   column + user:

   | Mask type | Effect on `purchase` |
   |-----------|----------------------|
   | `MASK` | redact all characters |
   | `MASK_SHOW_LAST_4` | `****hase` |
   | `MASK_SHOW_FIRST_4` | `purc****` |
   | `MASK_HASH` | a hash of the value |
   | `MASK_NULL` | `NULL` |

4. **Change the mask without touching SQL — from the console.** Open the console
   web UI at http://localhost:4200, find the masking policy row, and use the
   **New masking policy** form (or the **Enable/Disable** button) to adjust it.
   Re-run step 2 and watch the analyst's result change.

   > **On real CDP:** an analyst wouldn't edit the policy — a Ranger admin would
   > (that's the **03 Administrator** track). Here you get to see both sides.

5. **Peek at row filtering (the sibling control).** Masking hides *columns*; a
   Ranger **row-filter** policy hides *rows* (e.g. `region = 'EU'` for an EU
   analyst). The platform models it as `policyType: 2` — try adding one against
   `iceberg.analytics.orders` from Lab 1 via Ranger's UI (http://localhost:6080).

## Check yourself

- [ ] `admin` sees `purchase`; `analyst` does not (steps 1–2).
- [ ] Disabling the policy from the console makes `analyst` see `purchase` again
      (step 4).

## Going further

- Compare two mask types by editing the policy and re-querying.
- Next: [Lab 3 — a Superset dashboard](lab-03-superset-dashboard.md) over the
  same governed tables.
