#!/usr/bin/env bash
# Unit-test the alert rules the cluster runs, straight from the PrometheusRule
# objects: extract spec.groups, then `promtool test rules`. The assistant's
# rules are tested with its own repository's tests (they are a mirror).
set -euo pipefail
cd "$(dirname "$0")/.."
work=$(mktemp -d)
extract() { python3 -c "import sys,yaml; t=open(sys.argv[1]).read(); print(yaml.safe_dump({'groups': yaml.safe_load(t)['spec']['groups']}))" "$1"; }
extract apps/base/library/prometheusrule.yaml > "$work/library.rules.yaml"
cp observability/tests/library.test.yaml "$work/"
extract apps/base/assistant/prometheusrule.yaml > "$work/alerts.yaml"
curl -fsSL https://raw.githubusercontent.com/hasanozkan/llm-tool-calling-assistant/main/observability/alerts.test.yaml -o "$work/assistant.test.yaml"
cd "$work"
promtool check rules library.rules.yaml alerts.yaml
promtool test rules library.test.yaml assistant.test.yaml
