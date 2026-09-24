.PHONY: validate up smoke status down

validate:
	./scripts/validate.sh

up:
	./scripts/up.sh

smoke:
	./scripts/smoke.sh http://localhost:8080

status:
	flux get all -A

down:
	k3d cluster delete gitops-reference
