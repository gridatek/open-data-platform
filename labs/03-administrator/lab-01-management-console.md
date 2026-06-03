# 03 Administrator — Lab 1: The management console

**Time:** ~20 min · **Prereqs:** `make console`, `cd quickstart`

## Goal

Use the console as your Cloudera-Manager equivalent: see every service and its
health at a glance, and understand where that signal comes from.

## Steps

1. **Open the console.** Web UI at http://localhost:4200 — the **Services** panel
   shows each platform service with an `UP`/`DOWN` badge, the **Iceberg
   namespaces** it can browse, and the **Ranger policies** in force.

2. **Hit the API directly** (what the UI calls):

   ```bash
   curl -s http://localhost:8090/api/services | jq .
   ```

   Each entry is `{ name, status, detail }` — the console probes every service's
   health endpoint and reports `UP` only on a 2xx.

   > **On open-source:** in the laptop subset there is no Kubernetes, so "is it
   > up?" is a fast HTTP health probe.
   > **On real CDP:** the Management Console reads the **K8s API** for pod/replica
   > status. The console's API shape is identical — only the source changes
   > (Phase 4b swaps the probe for a K8s client).

3. **Cause a failure and watch it flip.** Stop one service and re-check:

   ```bash
   docker compose stop atlas
   curl -s http://localhost:8090/api/services | jq '.[] | select(.name=="atlas")'
   ```

   `atlas` now reports `DOWN`. Bring it back:

   ```bash
   docker compose start atlas
   ```

4. **Check the console's own health** (a service monitoring itself):

   ```bash
   curl -s http://localhost:8090/actuator/health
   ```

   > **On real CDP:** health roll-ups and per-service status are core Admin exam
   > material — knowing *where* a red service is, and why.

## Check yourself

- [ ] `/api/services` lists minio, iceberg-rest, trino, ranger, atlas (step 2).
- [ ] Stopping `atlas` flips it to `DOWN`; starting it restores `UP` (step 3).

## Going further

- Watch the UI refresh after stopping a service (reload the page).
- Next: [Lab 2 — Ranger policy administration](lab-02-ranger-admin.md).
