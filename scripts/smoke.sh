#!/usr/bin/env bash
# Prove the deployed service works, not just that its pod is Ready:
# register a book and a copy, register a member, borrow, and see the
# catalog's availability follow the loan (an event between two contexts).
set -euo pipefail
BASE="${1:-http://localhost:8080}"
j() { curl -fsS -H 'content-type: application/json' "$@"; }
field() { python3 -c "import json,sys; print(json.load(sys.stdin)$1)"; }

curl -fsS "$BASE/healthz" >/dev/null
ISBN="97800000$(date +%s | tail -c 6)"
j -X POST "$BASE/catalog/books" -d "{\"isbn\":\"$ISBN\",\"title\":\"Smoke Test\",\"author\":\"CI\"}" >/dev/null
COPY=$(j -X POST "$BASE/catalog/books/$ISBN/copies" | field "['copy_id']")
MEMBER=$(j -X POST "$BASE/lending/members" -d '{"name":"Smoke","tier":"standard"}' | field "['member_id']")
j -X POST "$BASE/lending/loans" -d "{\"member_id\":\"$MEMBER\",\"copy_id\":\"$COPY\"}" >/dev/null
AVAILABLE=$(curl -fsS "$BASE/catalog/search?q=$ISBN" | field "[0]['copies_available']")
if [ "$AVAILABLE" != "0" ]; then echo "smoke: expected 0 available after the loan, got $AVAILABLE"; exit 1; fi
echo "smoke: ok ($BASE) — borrowed $COPY, catalog shows it on loan"
