#!/usr/bin/env python3
"""Every metric a dashboard panel or an alert rule queries — and every label
it filters or groups by — must exist in a telemetry contract: the library's
specs/telemetry.yaml or the assistant's observability/telemetry.yaml. A panel
on a renamed or imaginary series is an empty graph nobody notices; here it is
a red build.
"""

import json
import re
import sys
import urllib.request
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
CONTRACTS = {
    "library": "https://raw.githubusercontent.com/hasanozkan/spec-driven-ddd-python/main/specs/telemetry.yaml",
    "assistant": "https://raw.githubusercontent.com/hasanozkan/llm-tool-calling-assistant/main/observability/telemetry.yaml",
}
SERIES = re.compile(r"\b(?:http_server|library|gen_ai|assistant)_[a-z0-9_]+\b")
# Label names appear in matchers {name="..."} and in by/without/on/ignoring (...).
MATCHERS = re.compile(r"\{([^}]*)\}")
GROUPING = re.compile(r"\b(?:by|without|on|ignoring|group_left|group_right)\s*\(([^)]*)\)")
MATCHER_LABEL = re.compile(r"([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:=~|!~|!=|=)")
ALWAYS = {"le", "job", "instance", "namespace", "pod", "service", "otel_scope_name"}


def known() -> tuple[set[str], set[str]]:
    names: set[str] = set()
    labels: set[str] = set(ALWAYS)
    for url in CONTRACTS.values():
        spec = yaml.safe_load(urllib.request.urlopen(url, timeout=30).read())  # noqa: S310 — fixed https URLs
        for m in spec["metrics"]:
            base = m["name"].replace(".", "_") + ("_seconds" if m.get("unit") == "s" else "")
            if m["type"] == "histogram":
                names.update({f"{base}_bucket", f"{base}_count", f"{base}_sum"})
            else:
                names.add(f"{base}_total")
            labels.update(a.replace(".", "_") for a in m.get("attributes", []))
    return names, labels


def split(expr: str) -> tuple[set[str], set[str]]:
    """(series, labels) an expression refers to."""
    labels = {lbl for block in MATCHERS.findall(expr) for lbl in MATCHER_LABEL.findall(block)}
    labels |= {x.strip() for block in GROUPING.findall(expr) for x in block.split(",") if x.strip()}
    bare = GROUPING.sub("", MATCHERS.sub("", expr))
    return set(SERIES.findall(bare)), labels


def queries() -> list[tuple[str, str]]:
    found: list[tuple[str, str]] = []
    for path in sorted((ROOT / "observability" / "dashboards").glob("*.json")):
        for panel in json.loads(path.read_text())["panels"]:
            for t in panel.get("targets", []):
                if panel.get("datasource", {}).get("type") == "prometheus":
                    found.append((f"{path.name}: {panel['title']}", t["expr"]))
    for path in sorted((ROOT / "apps" / "base").glob("*/prometheusrule.yaml")):
        doc = yaml.safe_load(path.read_text().split("\n", 2)[-1] if path.read_text().startswith("#") else path.read_text())
        for group in doc["spec"]["groups"]:
            for rule in group["rules"]:
                found.append((f"{path.parent.name}/{rule['alert']}", rule["expr"]))
    return found


def main() -> int:
    names, labels = known()
    bad: list[str] = []
    for where, expr in queries():
        series, used = split(expr)
        bad += [f"{where}: series {s} is in no telemetry contract" for s in sorted(series - names)]
        bad += [f"{where}: label {x} is in no telemetry contract" for x in sorted(used - labels)]
    print("\n".join(bad) if bad else f"queries: ok — {len(queries())} queries; every series and label is in a telemetry contract")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
