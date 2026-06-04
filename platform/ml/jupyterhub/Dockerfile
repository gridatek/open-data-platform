# JupyterHub + the single-user notebook packages it spawns. The base hub image
# ships only the hub, so add jupyterlab/notebook so spawned servers work.
FROM quay.io/jupyterhub/jupyterhub:5.2

RUN python3 -m pip install --no-cache-dir jupyterlab notebook

COPY jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py

EXPOSE 8000
CMD ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]
