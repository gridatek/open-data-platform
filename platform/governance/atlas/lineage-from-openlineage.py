#!/usr/bin/env python3
"""Bridge OpenLineage events into Atlas lineage.

Reads OpenLineage RunEvents (one JSON object per line) emitted automatically by
the Spark OpenLineage listener, extracts the input/output datasets + the job
name, maps them to the platform's Atlas qualified names
(`iceberg.<namespace>.<table>@odp`), and registers a DataSet -> Process ->
DataSet lineage graph in Atlas. So lineage *captured automatically* from a real
Spark run lands in Atlas — no hand-authored entities.

Usage:  lineage-from-openlineage.py <events.jsonl>
Env:    ATLAS_URL  (default http://localhost:21000)
        ATLAS_AUTH (default admin:admin)
"""
import base64
import json
import os
import sys
import urllib.request

ATLAS = os.environ.get("ATLAS_URL", "http://localhost:21000")
AUTH = os.environ.get("ATLAS_AUTH", "admin:admin")
NS = "odp"


def qn(name: str) -> str:
    # OpenLineage dataset name "smoke/events" -> "iceberg.smoke.events@odp"
    return f"iceberg.{name.replace('/', '.')}@{NS}"


def atlas(method: str, path: str, body=None):
    req = urllib.request.Request(
        ATLAS + path,
        method=method,
        data=json.dumps(body).encode() if body is not None else None,
    )
    req.add_header("Authorization", "Basic " + base64.b64encode(AUTH.encode()).decode())
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read() or "{}")


def main() -> None:
    events = [json.loads(line) for line in open(sys.argv[1]) if line.strip()]

    ins: set[str] = set()
    outs: set[str] = set()
    job = None
    for e in events:
        for i in e.get("inputs", []):
            ins.add(i["name"])
        for o in e.get("outputs", []):
            outs.add(o["name"])
            # the job that produced an output (strip the spark sub-job suffix)
            job = e.get("job", {}).get("name", "").split(".")[0] or job

    # ignore self-edges (a job that reads + writes the same dataset)
    ins -= outs
    if not outs:
        print("no output datasets in the OpenLineage events", file=sys.stderr)
        sys.exit(1)
    job = job or "spark_job"
    print(f"OpenLineage captured: inputs={sorted(ins)} -> job={job} -> outputs={sorted(outs)}")

    entities = []
    refs: dict[str, str] = {}

    def dataset(name: str) -> str:
        if name not in refs:
            guid = str(-(len(entities) + 1))
            entities.append(
                {
                    "typeName": "DataSet",
                    "guid": guid,
                    "attributes": {
                        "qualifiedName": qn(name),
                        "name": f"iceberg.{name.replace('/', '.')}",
                        "description": "Discovered automatically from OpenLineage.",
                    },
                }
            )
            refs[name] = guid
        return refs[name]

    in_guids = [dataset(n) for n in sorted(ins)]
    out_guids = [dataset(n) for n in sorted(outs)]
    proc_guid = str(-(len(entities) + 1))
    entities.append(
        {
            "typeName": "Process",
            "guid": proc_guid,
            "attributes": {
                "qualifiedName": f"{job}@{NS}",
                "name": job,
                "description": "Lineage captured automatically via OpenLineage from a Spark run.",
                "inputs": [{"guid": g, "typeName": "DataSet"} for g in in_guids],
                "outputs": [{"guid": g, "typeName": "DataSet"} for g in out_guids],
            },
        }
    )

    atlas("POST", "/api/atlas/v2/entity/bulk", {"entities": entities})
    print(f"registered {len(entities)} entities in Atlas (process '{job}@{NS}')")


if __name__ == "__main__":
    main()
