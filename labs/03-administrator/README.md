# 03 Administrator → CDP Administrator (CDP-2001 / 5001)

The operator's view: run the platform through the **console** (≈ Cloudera
Manager) — watch service health, administer **Ranger** policies, manage the
**service lifecycle**, and review **audit trails**.

This track lives in the control plane. Bring it up with governance + console:

```bash
make console        # lakehouse + Ranger/Atlas + the console API
make seed
docker compose -f docker-compose.yml -f docker-compose.governance.yml \
  -f docker-compose.console.yml up -d   # (make console already does this)
cd quickstart
```

Consoles you'll use: web UI http://localhost:4200 · console API
http://localhost:8090 · Ranger http://localhost:6080 (admin / rangerR0cks!).

## Labs

| # | Lab | Cert objective it maps to |
|---|-----|---------------------------|
| 01 | [The management console](lab-01-management-console.md) | Service catalog & health monitoring |
| 02 | [Ranger policy administration](lab-02-ranger-admin.md) | Create/manage access & masking policies |
| 03 | [Service lifecycle](lab-03-service-lifecycle.md) | Start/stop/scale/restart services |
| 04 | [Audit trails & access review](lab-04-audit-trails.md) | Audit logging and access review |

> **On real CDP:** an administrator works in the **Management Console** and
> **Ranger Admin** over services running on Kubernetes. Here the console plays
> Cloudera Manager and docker-compose plays the cluster; the *operations* — watch
> health, edit a policy, scale a service, read an audit — are the same skills.
