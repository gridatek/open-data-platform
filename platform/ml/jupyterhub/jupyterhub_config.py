# JupyterHub for the laptop subset (≈ Cloudera ML notebooks).
#
# Single node, dummy auth, and a spawner that doesn't need system user accounts —
# enough to log in and get a JupyterLab. Not for anything beyond local/dev.
c = get_config()  # noqa: F821

c.JupyterHub.bind_url = "http://0.0.0.0:8000"

# Any username; the shared dev password gates login. Dev only.
c.JupyterHub.authenticator_class = "dummy"
c.DummyAuthenticator.password = "jupyter"
c.Authenticator.admin_users = {"admin"}

# Spawn single-user servers as the hub's own user — no PAM / system accounts.
from jupyterhub.spawner import SimpleLocalProcessSpawner  # noqa: E402

c.JupyterHub.spawner_class = SimpleLocalProcessSpawner
c.Spawner.default_url = "/lab"
c.Spawner.start_timeout = 120
# The hub image runs as root, and jupyter-server refuses to run as root unless
# told to. Allow it for the spawned single-user servers (laptop subset only).
c.Spawner.args = ["--ServerApp.allow_root=True"]

# A pre-seeded admin API token so CI/scripts can drive the REST API (start a
# server, check status). Dev only — override in anything real.
c.JupyterHub.services = [
    {"name": "odp-smoke", "api_token": "odp-smoke-token"},
]
c.JupyterHub.load_roles = [
    {
        "name": "odp-smoke-role",
        "services": ["odp-smoke"],
        "scopes": ["admin:users", "admin:servers", "list:users", "read:hub"],
    }
]
