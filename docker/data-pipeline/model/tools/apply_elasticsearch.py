#!/usr/bin/env python3
"""Put the Elasticsearch definitions of ../elasticsearch (names in auto_apply_metadata.json) on the
stack, through scripts/es.sh. Order: component templates, ingest pipelines, index templates, indices
(created when missing; an existing index keeps its mapping and analyzers), search templates.

    python3 model/tools/apply_elasticsearch.py          # from docker/data-pipeline

A changed analyzer or field type needs the index rebuilt: delete it (scripts/es.sh delete-index
<index> --yes), run this again, then replay the rows (see ../README.md, "Rebuild an index").
"""
import json
import subprocess
import sys
from pathlib import Path

ES_DIR = Path(__file__).resolve().parents[1] / "elasticsearch"
STACK = ES_DIR.parents[1]


def es(method, path, body=None, check=True):
    args = [str(STACK / "scripts" / "es.sh"), "raw", method, path]
    if body is not None:
        args.append(json.dumps(body))
    out = subprocess.run(args, capture_output=True, text=True, cwd=STACK)
    if check and out.returncode != 0:
        sys.exit(f"{method} {path} failed: {out.stderr.strip()}")
    return out.returncode == 0


def load(name):
    return json.loads((ES_DIR / name).read_text())


def main():
    meta = load("auto_apply_metadata.json")
    for c in meta.get("component_templates", []):
        es("PUT", f"/_component_template/{c['name']}", load(c["filename"]))
        print(f"component template {c['name']}: put")
    for p in meta["ingest_pipelines"]:
        es("PUT", f"/_ingest/pipeline/{p['name']}", load(p["filename"]))
        print(f"ingest pipeline {p['name']}: put")
    for t in meta["index_templates"]:
        body = load(t["filename"])
        es("PUT", f"/_index_template/{t['name']}", {
            "index_patterns": t["index_patterns"],
            "composed_of": t.get("composed_of", []),
            "template": {"settings": body["settings"], "mappings": body["mappings"]},
            "_meta": {"source": f"model/elasticsearch/{t['filename']}"},
        })
        print(f"index template {t['name']}: put")
        # GET, not HEAD: `curl -X HEAD` waits for a body when the index exists
        if es("GET", f"/{t['index']}/_settings", check=False):
            print(f"index {t['index']}: exists, left unchanged")
        else:
            es("PUT", f"/{t['index']}", {})
            print(f"index {t['index']}: created from {t['name']}")
    for s in meta["search_templates"]:
        source = (ES_DIR / s["filename"]).read_text()
        es("PUT", f"/_scripts/{s['name']}", {"script": {"lang": "mustache", "source": source}})
        print(f"search template {s['name']}: put")


if __name__ == "__main__":
    main()
