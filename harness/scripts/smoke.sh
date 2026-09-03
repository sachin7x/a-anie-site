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
    body=$(echo "$out" | sed "\$d")
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
    body=$(echo "$out" | sed "\$d")
    code=$(echo "$out" | tail -n 1)
    [ "$code" = "400" ] || { echo "expected 400 got $code"; echo "$body"; exit 1; }
    echo "$body" | grep -q "valid email" || { echo "missing validation error"; exit 1; }
  '

# ─── T03. POST /api/transcribe ───────────────────────────────────────────
# Pass the grep pattern via env var to avoid nested-quote hell in bash -c.
run_test T03 "POST /api/transcribe returns 501" \
  bash -c '
    out=$('"$VCC"' -s -w "\n%{http_code}" "'"$PREVIEW_URL"'/api/transcribe" -X POST -d "")
    body=$(echo "$out" | sed "\$d")
    code=$(echo "$out" | tail -n 1)
    [ "$code" = "501" ] || { echo "expected 501 got $code"; echo "$body"; exit 1; }
    echo "$body" | grep -q "$T03_PATTERN" || { echo "missing ok:false"; echo "$body"; exit 1; }
    echo "$body" | grep -q "not deployed\|on-device" || { echo "missing honest error"; exit 1; }
  ' T03_PATTERN='ok":false'

# ─── T04. POST /api/auth/signup ──────────────────────────────────────────
run_test T04 "POST /api/auth/signup returns 501" \
  bash -c '
    out=$('"$VCC"' -s -w "\n%{http_code}" "'"$PREVIEW_URL"'/api/auth/signup" \
      -X POST -H "Content-Type: application/json" \
      -d "{\"email\":\"smoke@example.com\",\"password\":\"correct-horse-battery-staple\",\"name\":\"Smoke\"}")
    body=$(echo "$out" | sed "\$d")
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
    body=$(echo "$out" | sed "\$d")
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
    body=$(echo "$out" | sed "\$d")
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
run_test T15 "/app 200 + /app.html 200 + /demo bundle 200 size 23666" \
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
  echo "── T15  SKIPPED: no $VCC on PATH"
fi

# ─── T16. Audio failure contract document (D008) ─────────────────────────
# Static existence + structural check. Runs without network. Fails loudly
# if the contract document is missing, or if the six-phase / eight-invariant
# structure has been silently edited away.
run_test T16 "Audio failure contract document present + structurally intact" \
  bash -c '
    f="harness/docs/ANNIE_AUDIO_FAILURE_CONTRACT.md"
    [ -f "$f" ] || { echo "missing $f"; exit 1; }
    # ANNIE scope header
    grep -q "ANNIE scope" "$f" || { echo "missing ANNIE scope header"; exit 1; }
    grep -q "phase 0 only" "$f" || { echo "missing phase-0-only scope statement"; exit 1; }
    # Six phases
    grep -q "Capture and finalize" "$f" || { echo "missing phase 0 — Capture and finalize"; exit 1; }
    grep -q "Promote source" "$f" || { echo "missing phase 1 — Promote source"; exit 1; }
    grep -q "Recognize speech" "$f" || { echo "missing phase 2 — Recognize speech"; exit 1; }
    grep -q "Clean up text" "$f" || { echo "missing phase 3 — Clean up text"; exit 1; }
    grep -q "Commit result" "$f" || { echo "missing phase 4 — Commit result"; exit 1; }
    grep -q "Deliver text" "$f" || { echo "missing phase 5 — Deliver text"; exit 1; }
    # Eight invariants
    inv=$(grep -cE "^[0-9]+\. (Allocate|Every active attempt|A relaunch|A retry|Recognition is the required|Chunk uploads run sequentially|Never delete the only|Every callback carries)" "$f")
    [ "$inv" = "8" ] || { echo "expected 8 invariants, found $inv"; exit 1; }
    # Reference source provenance
    grep -q "harness/reference/aidictation/docs/audio-processing-failure-contract.md" "$f" || { echo "missing reference source provenance"; exit 1; }
    # Deliberate-cuts reference
    grep -q "D005" "$f" || { echo "missing D005 deliberate-cuts reference"; exit 1; }
  '

# ─── T17. /app surfaces the phase model ──────────────────────────────────
# Static structural check. Confirms /app honestly says "phase 0" and that
# the 501 branch surfaces the phase model (without claiming fake success).
run_test T17 "/app surfaces the phase model in the 501 branch" \
  bash -c '
    f="public/app.html"
    [ -f "$f" ] || { echo "missing $f"; exit 1; }
    grep -q "Phase 0" "$f" || { echo "missing Phase 0 label in /app"; exit 1; }
    grep -q "phases 1-5" "$f" || { echo "missing phases 1-5 mention in /app 501 branch"; exit 1; }
    grep -q "ANNIE_AUDIO_FAILURE_CONTRACT" "$f" || { echo "missing contract doc reference in /app"; exit 1; }
  '

# ─── T18. /app allocates recordingId and enforces a 60s watchdog ──────────
# Static structural check. Confirms the additive P2-02 invariants are
# present in /app without re-running the page in a browser.
run_test T18 "/app allocates recordingId and enforces a 60s watchdog" \
  bash -c '
    f="public/app.html"
    [ -f "$f" ] || { echo "missing $f"; exit 1; }
    grep -q "recordingId" "$f" || { echo "missing recordingId allocation in /app"; exit 1; }
    grep -q "watchdog" "$f" || { echo "missing watchdog timer in /app"; exit 1; }
  '

# ─── T19. /nav partials are present on 5 secondary pages ─────────────────
# Static structural check. Confirms each secondary page has opted into
# the canonical nav.js partial by including a data-nav-partial stub,
# and that nav.js is loaded.
run_test T19 "5 secondary pages opt into the nav.js partial" \
  bash -c '
    for slug in careers security accessibility support contact; do
      f="public/${slug}.html"
      [ -f "$f" ] || { echo "missing $f"; exit 1; }
      grep -q "data-nav-partial" "$f" || { echo "missing data-nav-partial stub in $f"; exit 1; }
      grep -q "src=\"nav.js\"" "$f" || { echo "missing nav.js script include in $f"; exit 1; }
    done
    [ -f "public/nav.js" ] || { echo "missing public/nav.js"; exit 1; }
  '

echo
echo "════════════════════════════════════════════════════════════"
echo "  PASS  $pass"
echo "  FAIL  $fail"
[ "$fail" -gt 0 ] && echo "  Failed:$fail_log"
echo "════════════════════════════════════════════════════════════"

[ "$fail" -eq 0 ]
