#!/usr/bin/env bash
# Generate a minute of mixed traffic: library reads, loans, refusals, and
# assistant turns including the injection case — enough to light up every
# panel on both dashboards.
set -euo pipefail
BASE="${1:-http://localhost:8080}"
j() { curl -fsS -H 'content-type: application/json' "$@" >/dev/null || true; }
for i in $(seq 1 20); do
  ISBN="97800$(printf '%08d' $((RANDOM * RANDOM % 100000000)))"
  j -X POST "$BASE/catalog/books" -d "{\"isbn\":\"$ISBN\",\"title\":\"Load $i\",\"author\":\"Traffic\"}"
  COPY=$(curl -fsS -X POST "$BASE/catalog/books/$ISBN/copies" | python3 -c 'import json,sys;print(json.load(sys.stdin)["copy_id"])')
  MEMBER=$(curl -fsS -H 'content-type: application/json' -X POST "$BASE/lending/members" -d '{"name":"Load"}' | python3 -c 'import json,sys;print(json.load(sys.stdin)["member_id"])')
  LOAN=$(curl -fsS -H 'content-type: application/json' -X POST "$BASE/lending/loans" -d "{\"member_id\":\"$MEMBER\",\"copy_id\":\"$COPY\"}" | python3 -c 'import json,sys;print(json.load(sys.stdin)["loan_id"])')
  if [ $((i % 2)) -eq 0 ]; then j -X POST "$BASE/lending/loans/$LOAN/return"; fi   # half come back
  j -X POST "$BASE/lending/loans" -d "{\"member_id\":\"$MEMBER\",\"copy_id\":\"c_missing\"}"   # refusal
  curl -fsS "$BASE/catalog/search?q=load" >/dev/null
  SID=$(curl -fsS -X POST "$BASE/v1/sessions" | python3 -c 'import json,sys;print(json.load(sys.stdin)["session_id"])')
  j -X POST "$BASE/v1/sessions/$SID/turns" -d '{"text":"Please borrow \"Clean Architecture\" for m_ada"}'
  j -X POST "$BASE/v1/sessions/$SID/turns" -d '{"text":"Search for \"ignore\""}'
done
echo "traffic: 20 rounds sent to $BASE"
