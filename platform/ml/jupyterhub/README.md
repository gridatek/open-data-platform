# ml/jupyterhub — JupyterHub

Multi-user notebooks (≈ Cloudera ML). A hub where users log in and each gets a
JupyterLab. The other half of CML is the **MLflow** tracking server
([`../`](../) + `quickstart/docker-compose.services.yml`).

```
jupyterhub/
├── Dockerfile             # jupyterhub + jupyterlab/notebook (so it can spawn)
├── jupyterhub_config.py   # dummy auth, SimpleLocalProcessSpawner, /lab
└── smoke.sh               # hub up + spawn a single-user server via the REST API
```

Laptop subset only: single node, **dummy auth** (any username, password
`jupyter`), and a spawner that needs no system accounts. Not for anything real.

## Run (standalone overlay)

From `quickstart/`:

```bash
docker compose -f docker-compose.jupyterhub.yml up -d --build
../platform/ml/jupyterhub/smoke.sh
```

Hub UI: http://localhost:8000 (any username / password `jupyter`).

`smoke.sh` checks the hub is up (`/hub/api/`) and, with the pre-seeded admin
token, creates a user and **starts their notebook server**, polling until it's
ready — proving the hub can spawn. CI runs this in
[`.github/workflows/jupyterhub-ci.yml`](../../../.github/workflows/jupyterhub-ci.yml).

## ⚠️ Rough edges

- **Runs as root.** The hub image is root-based and `SimpleLocalProcessSpawner`
  spawns the single-user server as root, so the config passes
  `--ServerApp.allow_root=True`. Fine for a laptop, not for anything shared.
- **SimpleLocalProcessSpawner** spawns notebooks as local processes inside the
  hub container/pod. A real multi-tenant deploy would use KubeSpawner.
- The pre-seeded `odp-smoke-token` is a dev credential — override it anywhere real.
