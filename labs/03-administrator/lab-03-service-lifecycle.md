# 03 Administrator — Lab 3: Service lifecycle

**Time:** ~20 min · **Prereqs:** platform up, `cd quickstart`

## Goal

Manage the running services: inspect, restart, and scale. You'll also see where
the console's control plane is wired vs. stubbed, so you understand the K8s path.

## Steps

1. **See what's running.**

   ```bash
   docker compose ps
   ```

   This is the cluster inventory — the console's Services panel is the friendly
   view of the same thing.

2. **Restart a service** (the laptop-subset way):

   ```bash
   docker compose restart superset
   docker compose logs --tail=20 superset
   ```

   > **On open-source:** docker-compose restarts the container.
   > **On real CDP:** an admin restarts/rolls a service from the Management
   > Console, which tells Kubernetes to recreate the pods.

3. **Try it through the console API** — and meet the honest boundary:

   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" \
     -X POST http://localhost:8090/api/services/superset/restart
   ```

   Returns **501**. The endpoint exists and defines the contract, but lifecycle
   control needs the Kubernetes API, which the laptop subset doesn't have.

   > **On real CDP:** this call would scale/restart a Deployment. Wiring the K8s
   > client (apply Helm release / `kubectl scale`) is the platform's **Phase 4b**
   > — see `console/api/.../control/ServiceControlController.java`.

4. **Scaling — the concept.** Trino scales by adding *workers*:

   - **On Kubernetes (the umbrella chart):**

     ```bash
     helm upgrade odp platform/umbrella --set trino.server.workers=4
     # or: kubectl scale deploy/odp-trino-worker --replicas=4
     ```

   - **In docker-compose:** the laptop subset runs a single Trino; horizontal
     scaling is a K8s concern. (Stateless services *can* use
     `docker compose up -d --scale <svc>=N`, but most here are singletons.)

   > **On real CDP:** sizing/scaling CDW virtual warehouses and CDE is a central
   > Admin objective — you'd set worker counts and autoscaling, not run containers.

## Check yourself

- [ ] `docker compose ps` lists the running services (step 1).
- [ ] `superset` comes back healthy after a restart (step 2).
- [ ] The console restart endpoint returns `501` (step 3) — expected, by design.

## Going further

- Read `ServiceControlController.java` to see the contract that Phase 4b fills.
- Next: [Lab 4 — audit trails & access review](lab-04-audit-trails.md).
