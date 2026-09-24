.PHONY: validate up smoke status down grafana traffic

validate:
	./scripts/validate.sh

up:
	./scripts/up.sh

smoke:
	./scripts/smoke.sh http://localhost:8080

status:
	flux get all -A

# Grafana (anonymous, local only) on http://localhost:3000 — dashboards "Library" and "Assistant".
grafana:
	kubectl -n observability port-forward svc/kube-prometheus-stack-grafana 3000:80

# A little load so the dashboards have something to show.
traffic:
	./scripts/traffic.sh http://localhost:8080

down:
	k3d cluster delete gitops-reference
