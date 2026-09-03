#!/usr/bin/env bash
# harness/scripts/smoke.sh
#
# Canonical smoke test for the ANNIE marketing site.
# Runs the API contract tests (T01-T08) and the /app shell tests (T10-T15)
# against the preview URL, with Vercel SSO bypass via `vercel curl`.
#
# Override the preview URL:
#   PREVIEW_URL=https://a-anie-site-<hash>-sachin7xs-projects.vercel.app ./smoke.sh
#
# Exit code 0 = all green, 1 = at least one test failed.
# The script never modifies the remote. Read-only round-trips.

set -u

PREVIEW_URL="${PREVIEW_URL:-https://a-anie-site-raqw1co8r-sachin7xs-projects.vercel.app}"

# Pick the curl tool. `vercel curl` is the SSO-bypass path; `curl` is the
# public-traffic path. The script records both, so a future regression in
# either side will surface.
VCC="${VCC:-vercel curl}"

if ! command -v "$VCC" >/dev/null 2>&1; then
  echo "WARN: '$VCC' not found on PATH. Skipping network tests; running static checks only."
  echo "      Install Vercel CLI (npm i -g vercel) and re-run for full coverage."
  NETWORK=0
else
  NETWORK=1
fi

pass=0
fail=0
fail_log=""

run_test() {
  local id="$1"
  local desc="$2"
  shift 2
  echo "── $id  $desc"
  local out
  out="$("$@" 2>&1)"
  local rc=$?
  if [ $rc -eq 0 ]; then
    pass=$((pass + 1))
    echo "   PASS"
  else
    fail=$((fail + 1))
    echo "   FAIL  (rc=$rc)"
    echo "$out" | sed 's/^/     /'
    fail_log="$fail_log
$id: $desc"
  fi
}

echo "Preview URL: $PREVIEW_URL"
echo "Curl tool:   $VCC"
echo

# ─── T01. POST /api/contact valid ────────────────────────────────────────
run_test T01 "POST /api/contact valid body" \
  bash -c '
    out=$('"$VCC"' -s -w "\n%{http_code}" "'"$PREVIEW_URL"'/api/contact" \
      -X POST -H "Content-Type: application/json" \
      -d "{\"name\":\"Smoke Test\",\"email\":\"smoke@example.com\",\"topic\":\"Feedback\",\"message\":\"This is a 30-character message body for testing.\"}")
    body=$(echo "$out" | head -n -1)
    code=$(echo "$out" | tail -n 1)
    [ "$code" = "200" ] || { echo "expected 200 got $code"; echo "$body"; exit 1; }
    echo "$body" | grep -q "Logged\|sachin@a-anie.example" || { echo "missing honest message"; echo "$body"; exit 1; }
    echo "$body" | grep -q "Sachin will reply soon" && { echo "regression to old lying message"; exit 1; } || true
  '

# ─── T02. POST /api/contact bad email ────────────────────────────────────
run_test T02 "POST /api/contact bad email" \
  bash -c '
    out=$('"$VCC"' -s -w "\n%{http_code}" "'"$PREVIEW_URL"'/api/contact" \
      -X POST -H "Content-Type: application/json" \
      -d "{\"name\":\"Smoke\",\"email\":\"not-an-email\",\"topic\":\"Feedback\",\"message\":\"This is a 30-character message body for testing.\"}")
    body=$(echo "$out" | head -n -1)
    code=$(echo "$out" | tail -n 1)
    [ "$code" = "400" ] || { echo "expected 400 got $code"; echo "$body"; exit 1; }
    echo "$body" | grep -q "valid email" || { echo "missing validation error"; exit 1; }
  '

# ─── T03. POST /api/transcribe ───────────────────────────────────────────
run_test T03 "POST /api/transcribe returns 501" \
  bash -c '
    out=$('"$VCC"' -s -w "\n%{http_code}" "'"$PREVIEW_URL"'/api/transcribe" -X POST -d "")
    body=$(echo "$out" | head -n -1)
    code=$(echo "$out" | tail -n 1)
    [ "$code" = "501" ] || { echo "expected 501 got $code"; echo "$body"; exit 1; }
    echo "$body" | grep -q '"'"'ok':false'"'"' || { echo "missing ok:false"; echo "$body"; exit 1; }
    echo "$body" | grep -q "not deployed\|on-device" || { echo "missing honest error"; exit 1; }
  '

# ─── T04. POST /api/auth/signup ──────────────────────────────────────────
run_test T04 "POST /api/auth/signup returns 501" \
  bash -c '
    out=$('"$VCC"' -s -w "\n%{http_code}" "'"$PREVIEW_URL"'/api/auth/signup" \
      -X POST -H "Content-Type: application/json" \
      -d "{\"email\":\"smoke@example.com\",\"password\":\"correct-horse-battery-staple\",\"name\":\"Smoke\"}")
    body=$(echo "$out" | head -n -1)
    code=$(echo "$out" | tail -n 1)
    [ "$code" = "501" ] || { echo "expected 501 got $code"; echo "$body"; exit 1; }
    echo "$body" | grep -q "Signup" || { echo "missing honest signup error"; exit 1; }
  '

# ─── T05. POST /api/auth/verify-otp ──────────────────────────────────────
run_test T05 "POST /api/auth/verify-otp returns 501" \
  bash -c '
    out=$('"$VCC"' -s -w "\n%{http_code}" "'"$PREVIEW_URL"'/api/auth/verify-otp" \
      -X POST -H "Content-Type: application/json" \
      -d "{\"email\":\"smoke@example.com\",\"code\":\"123456\"}")
    body=$(echo "$out" | head -n -1)
    code=$(echo "$out" | tail -n 1)
    [ "$code" = "501" ] || { echo "expected 501 got $code"; echo "$body"; exit 1; }
    echo "$body" | grep -q "verification\|not enabled" || { echo "missing honest verify error"; exit 1; }
  '

# ─── T06. POST /api/auth/login ───────────────────────────────────────────
run_test T06 "POST /api/auth/login returns 501" \
  bash -c '
    out=$('"$VCC"' -s -w "\n%{http_code}" "'"$PREVIEW_URL"'/api/auth/login" \
      -X POST -H "Content-Type: application/json" \
      -d "{\"email\":\"smoke@example.com\",\"password\":\"any-password\"}")
    body=$(echo "$out" | head -n -1)
    code=$(echo "$out" | tail -n 1)
    [ "$code" = "501" ] || { echo "expected 501 got $code"; echo "$body"; exit 1; }
    echo "$body" | grep -q "Login" || { echo "missing honest login error"; exit 1; }
  '

# ─── T07. GET /api/auth/login ────────────────────────────────────────────
run_test T07 "GET /api/auth/login returns 405" \
  bash -c '
    code=$('"$VCC"' -s -o /dev/null -w "%{http_code}" "'"$PREVIEW_URL"'/api/auth/login")
    [ "$code" = "405" ] || { echo "expected 405 got $code"; exit 1; }
  '

# ─── T10-T14. /app shell static checks ───────────────────────────────────
APP_HTML="public/app.html"
[ -f "$APP_HTML" ] || APP_HTML="./public/app.html"

run_test T10 "501 branch + verbatim message in /app" \
  bash -c '
    f="'"$APP_HTML"'"
    [ -f "$f" ] || { echo "missing $f"; exit 1; }
    n=$(grep -c "not_implemented\|Backend not deployed" "$f")
    [ "$n" -ge 2 ] || { echo "expected >=2 matches, got $n"; exit 1; }
  '

run_test T11 "401 branch + Vercel SSO message in /app" \
  bash -c '
    f="'"$APP_HTML"'"
    n=$(grep -c "Vercel SSO\|deployment-protection" "$f")
    [ "$n" -ge 2 ] || { echo "expected >=2 matches, got $n"; exit 1; }
  '

run_test T12 "200 branch + no fake-transcript markers in /app" \
  bash -c '
    f="'"$APP_HTML"'"
    n=$(grep -c "out.j.text\|j.text" "$f")
    [ "$n" -ge 1 ] || { echo "expected >=1 match, got $n"; exit 1; }
    m=$(grep -ci "fake\|sample.*transcript\|placeholder.*text" "$f")
    [ "$m" = "0" ] || { echo "found $m fake-transcript markers"; exit 1; }
  '

run_test T13 "Space-to-record listener in /app" \
  bash -c '
    f="'"$APP_HTML"'"
    n=$(grep -c "Hold Space\|Space.*record\|key.*Space" "$f")
    [ "$n" -ge 1 ] || { echo "expected >=1 match, got $n"; exit 1; }
  '

run_test T14 "AnalyserNode + getByteFrequencyData in /app" \
  bash -c '
    f="'"$APP_HTML"'"
    n=$(grep -c "AnalyserNode\|getByteFrequencyData\|createMediaStreamSource" "$f")
    [ "$n" -ge 1 ] || { echo "expected >=1 match, got $n"; exit 1; }
  '

# ─── T15. /app, /app.html, /demo/dist/web-demo.js reachability ───────────
if [ "$NETWORK" = "1" ]; then
run_test T15 "/app 200 + /app.html 200 + /demo bundle 200 (23666 bytes)" \
  bash -c '
    a=$('"$VCC"' -s -o /dev/null -w "%{http_code}" "'"$PREVIEW_URL"'/app")
    [ "$a" = "200" ] || { echo "/app expected 200 got $a"; exit 1; }
    b=$('"$VCC"' -s -o /dev/null -w "%{http_code}" "'"$PREVIEW_URL"'/app.html")
    [ "$b" = "200" ] || { echo "/app.html expected 200 got $b"; exit 1; }
    c=$('"$VCC"' -s -o /dev/null -w "%{http_code} %{size_download}" "'"$PREVIEW_URL"'/demo/dist/web-demo.js")
    code=$(echo "$c" | awk "{print \$1}")
    sz=$(echo "$c" | awk "{print \$2}")
    [ "$code" = "200" ] || { echo "/demo bundle expected 200 got $code"; exit 1; }
    [ "$sz" = "23666" ] || { echo "/demo bundle size expected 23666 got $sz"; exit 1; }
  '
else
  echo "── T15  SKIPPED (no '$VCC' on PATH)"
fi

echo
echo "════════════════════════════════════════════════════════════"
echo "  PASS  $pass"
echo "  FAIL  $fail"
[ "$fail" -gt 0 ] && echo "  Failed:$fail_log"
echo "════════════════════════════════════════════════════════════"

[ "$fail" -eq 0 ]
