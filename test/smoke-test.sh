#!/usr/bin/env bash
# Boot the image and exercise what the template advertises: the instance
# comes up healthy, our settings.yml is actually loaded (curated engines
# enabled, google disabled), and /search?format=json answers with parseable
# JSON over a plain GET. Engine *results* are not asserted — CI runner IPs
# get CAPTCHA'd by upstream engines, so we only require a well-formed
# response. CI runs this before any image is published.
#
# Usage: ./test/smoke-test.sh <image>
set -euo pipefail

IMAGE="${1:?usage: smoke-test.sh <image>}"
NAME="searxng-smoke-$$"
PORT="${SMOKE_PORT:-18080}"
BASE="http://localhost:$PORT"
TMP="$(mktemp -d)"

cleanup() {
  docker logs "$NAME" 2>&1 | tail -40 || true
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  rm -rf "$TMP"
}
trap cleanup EXIT

docker run -d --name "$NAME" \
  -e SEARXNG_SECRET=smoke-test-secret \
  -p "$PORT:8080" \
  "$IMAGE" >/dev/null

echo "==> waiting for /healthz"
ok=""
for _ in $(seq 1 30); do
  if curl -fsS "$BASE/healthz" >/dev/null 2>&1; then
    ok=1
    break
  fi
  sleep 2
done
if [ -z "$ok" ]; then
  echo "FAIL: instance never became healthy" >&2
  exit 1
fi

echo "==> settings.yml is loaded (engine curation visible in /config)"
curl -fsS "$BASE/config" -o "$TMP/config.json"
python3 - "$TMP/config.json" <<'EOF'
import json, sys

config = json.load(open(sys.argv[1]))
engines = {e["name"]: e["enabled"] for e in config["engines"]}

for name in ("brave", "duckduckgo", "github", "arxiv", "pypi"):
    assert engines.get(name), f"expected engine enabled: {name}"
for name in ("google", "bing"):
    assert not engines.get(name, False), f"expected engine disabled: {name}"
EOF

echo "==> JSON search API answers a plain GET"
curl -fsS "$BASE/search?q=smoke+test&format=json" -o "$TMP/search.json"
python3 - "$TMP/search.json" <<'EOF'
import json, sys

result = json.load(open(sys.argv[1]))
assert "results" in result, "search response missing 'results'"
EOF

echo "PASS"
trap - EXIT
docker rm -f "$NAME" >/dev/null 2>&1 || true
rm -rf "$TMP"
