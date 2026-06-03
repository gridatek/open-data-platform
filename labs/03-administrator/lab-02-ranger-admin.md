# 03 Administrator — Lab 2: Ranger policy administration

**Time:** ~30 min · **Prereqs:** `make console`, `make seed`, `cd quickstart`

## Goal

Administer governance: create and manage the access and masking policies that
every engine enforces. You'll work both the console (the platform's admin UI) and
Ranger Admin directly.

Load the demo policies if you haven't:

```bash
../platform/governance/load-policies.sh
```

## Steps

1. **See the policy inventory** through the console:

   ```bash
   curl -s http://localhost:8090/api/policies | jq .
   ```

   You'll see `allow-select-events` (`ACCESS`) and `mask-events-kind-for-analyst`
   (`MASKING`), each with an `id` and `enabled` flag.

2. **Create a masking policy from the console UI.** Open http://localhost:4200,
   expand **+ New masking policy**, and create one — e.g. mask `region` of
   `iceberg.analytics.orders` for `analyst` with type `MASK_SHOW_FIRST_4`. Submit;
   it appears in the table.

   > **On open-source:** the console `POST`s a Ranger policy document via its API.
   > **On real CDP:** an admin builds the same policy in **Ranger Admin** — this
   > is the core governance-administration objective.

3. **Toggle a policy on/off.** Use the **Disable**/**Enable** button on the
   masking row (or the API):

   ```bash
   ID=$(curl -s http://localhost:8090/api/policies | jq -r '.[] | select(.type=="MASKING") | .id' | head -n1)
   curl -s -X POST http://localhost:8090/api/policies/$ID/enabled \
     -H 'Content-Type: application/json' -d '{"enabled":false}'
   ```

   Wait ~30s and have an analyst re-query — the mask is gone. Re-enable it.

4. **Work Ranger Admin directly.** Open http://localhost:6080
   (admin / rangerR0cks!) → service `trino-odp` → **Masking** and **Access** tabs.
   You'll see the same policies the console created — one source of truth.

   > **On real CDP:** Ranger Admin is the same UI; understanding access vs masking
   > vs row-filter policy types and user/group bindings is tested Admin material.

5. **Understand the three policy types** an admin manages:

   | Type | `policyType` | Controls |
   |------|--------------|----------|
   | Access | 0 | who may select/insert on a resource |
   | Masking | 1 | how a column appears per user |
   | Row filter | 2 | which rows a user sees |

## Check yourself

- [ ] The console lists both the access and masking policies (step 1).
- [ ] A policy you create in the UI shows up in Ranger Admin (steps 2, 4).
- [ ] Disabling the mask via the console changes the analyst's query result (step 3).

## Going further

- Add a **row-filter** policy in Ranger Admin (`region = 'EU'` for a user) and
  test it from Trino.
- Next: [Lab 3 — service lifecycle](lab-03-service-lifecycle.md).
