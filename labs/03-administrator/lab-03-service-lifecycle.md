# 03 Administrator — Lab 3: Service lifecycle

**Time:** ~20 min · **Prereqs:** platform up, `cd quickstart`

## Goal

Manage the running services: inspect, restart, and scale. You'll see how the
console's restart/scale run against the Kubernetes API (and why the same call
returns 501 in the docker-compose subset), so you understand the K8s path.

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

3. **Try it through the console API** — and meet the boundary between the two paths:

   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" \
     -X POST http://localhost:8090/api/services/superset/restart
   ```

   Returns **501** *here*. The endpoint is real, but restart/scale act on a
   Kubernetes Deployment — and the docker-compose laptop subset has no cluster,
   so there's no `ServiceControlService` bean and it answers 501.

   > **On Kubernetes (the umbrella chart):** the same call *works* — the console
   > runs with an RBAC'd ServiceAccount and rolling-restarts (or scales) the
   > Deployment through the K8s API. `kind-ci` exercises this path. See
   > `console/api/.../control/KubernetesServiceControlService.java`.
   > **On real CDP:** the Management Console restarts/scales a Deployment the same way.

4. **Scaling — the concept.** Trino scales by adding *workers*:

   - **On Kubernetes (the umbrella chart):**

     ```bash
     helm upgrade odp platform/umbrella --set trino.server.workers=4
     # or: kubectl scale deploy/trino-worker --replicas=4
     # or, through the console: POST /api/services/trino-worker/scale {"replicas":4}
     ```

   - **In docker-compose:** the laptop subset runs a single Trino; horizontal
     scaling is a K8s concern. (Stateless services *can* use
     `docker compose up -d --scale <svc>=N`, but most here are singletons.)

   > **On real CDP:** sizing/scaling CDW virtual warehouses and CDE is a central
   > Admin objective — you'd set worker counts and autoscaling, not run containers.

## Check yourself

- [ ] `docker compose ps` lists the running services (step 1).
- [ ] `superset` comes back healthy after a restart (step 2).
- [ ] The console restart endpoint returns `501` in the laptop subset (step 3) —
      no cluster here; on Kubernetes it rolling-restarts the Deployment.

## Going further

- Read `KubernetesServiceControlService.java` to see how restart/scale hit the
  K8s API, and the `console` chart's `rbac.yaml` for the Role that allows it.
- Next: [Lab 4 — audit trails & access review](lab-04-audit-trails.md).
