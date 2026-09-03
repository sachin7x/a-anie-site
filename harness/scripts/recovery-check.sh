#!/usr/bin/env bash
# harness/scripts/recovery-check.sh
#
# Filesystem ↔ STATE.md divergence detector. Run after any change to
# /public/, /api/, or /harness/state/ to make sure the on-disk state
# matches what the harness thinks is true.
#
# This script is intentionally a grep + stat combo, not a parsing tool.
# It is meant to fail loudly on obvious drifts, not on subtle ones.
#
# Exit code 0 = no drift, 1 = drift detected.

set -u

REPO_ROOT="${REPO_ROOT:-/Users/sachin/Pictures/ANNIE}"
cd "$REPO_ROOT" || { echo "cannot cd to $REPO_ROOT"; exit 2; }

fail=0
report=""

note() {
  report="$report
$1"
}

check_exists() {
  local p="$1"
  local label="$2"
  if [ ! -e "$p" ]; then
    note "MISSING $label  ($p)"
    fail=$((fail + 1))
  fi
}

check_grep() {
  local pattern="$1"
  local file="$2"
  local label="$3"
  if [ ! -f "$file" ]; then
    note "MISSING file for grep  ($file)"
    fail=$((fail + 1))
    return
  fi
  if ! grep -qE "$pattern" "$file"; then
    note "DRIFT   $label  (pattern '$pattern' not in $file)"
    fail=$((fail + 1))
  fi
}

# 1. Core structure
echo "── 1. Core structure"
check_exists "harness/STATE.md" "harness memory"
check_exists "harness/state/facts.md" "facts ledger"
check_exists "harness/state/decisions.md" "decisions ledger"
check_exists "harness/state/open-questions.md" "open-questions ledger"
check_exists "harness/state/inferences.md" "inferences ledger"
check_exists "harness/state/hypotheses.md" "hypotheses ledger"
check_exists "harness/agents/00-root.md" "root agent spec"
check_exists "harness/agents/01-frontend.md" "frontend agent spec"
check_exists "harness/agents/02-backend.md" "backend agent spec"
check_exists "harness/agents/03-evidence.md" "evidence agent spec"
check_exists "harness/agents/04-verification.md" "verification agent spec"
check_exists "harness/docs/guide.md" "voice-dictation paper"
check_exists "harness/docs/ARCHITECTURE.md" "architecture map"
check_exists "harness/tests/api-contracts.md" "API contract tests"
check_exists "harness/tests/app-shell.md" "app shell tests"
check_exists "harness/scripts/smoke.sh" "smoke script"
check_exists "harness/scripts/recovery-check.sh" "recovery script"

# 2. Api surface
echo "── 2. API surface"
check_exists "api/contact.js" "contact handler"
check_exists "api/transcribe.js" "transcribe stub"
check_exists "api/auth/signup.js" "signup stub"
check_exists "api/auth/verify-otp.js" "verify-otp stub"
check_exists "api/auth/login.js" "login stub"

# 3. D001 / D002 / D007 codifications
echo "── 3. Decision codifications"
check_grep "ok.*false" "api/transcribe.js" "D001 — transcribe uses {ok,error}"
check_grep "ok.*false" "api/auth/signup.js" "D001 — signup uses {ok,error}"
check_grep "ok.*false" "api/auth/login.js" "D001 — login uses {ok,error}"
check_grep "ok.*false" "api/auth/verify-otp.js" "D001 — verify-otp uses {ok,error}"
check_grep "Logged" "api/contact.js" "D007 — contact uses honest logged message"
check_grep "createAnalyser|getByteFrequencyData|createMediaStreamSource" "public/app.html" "D002 — /app is the wispr-style entry (live waveform analyser present)"

# 4. Wispr mirror integrity (F002)
echo "── 4. Wispr mirror integrity"
if [ -f "public/demo/dist/web-demo.js" ]; then
  sz=$(wc -c < "public/demo/dist/web-demo.js" | tr -d ' ')
  if [ "$sz" != "23666" ]; then
    note "DRIFT   F002 — wispr bundle size changed (got $sz, expected 23666)"
    fail=$((fail + 1))
  fi
else
  note "MISSING public/demo/dist/web-demo.js"
  fail=$((fail + 1))
fi

# 5. Bootstrap SRI (F001)
# Every page that loads Bootstrap must pin it with an SRI hash. Pages that
# deliberately do not use Bootstrap (e.g. legal documents like terms.html
# that render via styles.css only) are excluded by name, not by a generic
# skip rule — that way the test fails loudly if a new page is added that
# loads Bootstrap without the hash.
echo "── 5. Bootstrap SRI hash present on every HTML file that loads Bootstrap"
for f in public/*.html; do
  base=$(basename "$f")
  case "$base" in
    terms.html) continue ;;  # legal page, no Bootstrap by design
  esac
  if grep -q "cdn.jsdelivr.net/npm/bootstrap" "$f" && ! grep -q 'integrity="sha384-' "$f"; then
    note "DRIFT   F001 — Bootstrap loaded without SRI hash in $f"
    fail=$((fail + 1))
  fi
done

# 6. vercel.json cleanliness (cleanUrls + /api/v1 rewrite)
echo "── 6. vercel.json invariants"
check_exists "vercel.json" "vercel config"
if [ -f "vercel.json" ]; then
  if ! grep -q 'cleanUrls' "vercel.json"; then
    note "DRIFT   vercel.json missing cleanUrls"
    fail=$((fail + 1))
  fi
  if ! grep -q '/api/v1/' "vercel.json"; then
    note "DRIFT   vercel.json missing /api/v1 rewrite"
    fail=$((fail + 1))
  fi
fi

# 7. STATE.md references current preview URL
echo "── 7. STATE.md references a preview URL"
check_grep 'a-anie-site.*vercel.app' "harness/STATE.md" "preview URL in STATE.md"

# 8. No fabrication (D001 / D007 anti-fabrication contract)
# The site contract is: no fake "Welcome back, <name>!" greetings, no fake
# session tokens, no fake "Logged in" toasts, no fabricated user names.
# We anchor the check on positive signals — concrete honest markers that
# must be present in every stub — rather than a fragile "fake"-keyword
# regex. A real fabrication would *replace* these honest strings with a
# lying success copy; if the honest string disappears, the check fails.
echo "── 8. Anti-fabrication"
check_grep "not deployed"     "api/transcribe.js"      "D001 — transcribe returns honest 'not deployed'"
check_grep "not enabled yet"  "api/auth/signup.js"     "D001 — signup returns honest 'not enabled yet'"
check_grep "not enabled yet"  "api/auth/login.js"      "D001 — login returns honest 'not enabled yet'"
check_grep "not enabled yet"  "api/auth/verify-otp.js" "D001 — verify-otp returns honest 'not enabled yet'"
check_grep "Logged"           "api/contact.js"         "D007 — contact returns honest 'Logged' message"
# Regression: if a fake success greeting ever lands in a handler, this fails.
if grep -rIE "Welcome back, [A-Z][a-z]+!|sessionToken *= *['\"][A-Za-z0-9]{16,}|You are now logged in as [A-Z]" api/ public/ 2>/dev/null; then
  note "FABRICATION  a fake success greeting or session token was added"
  fail=$((fail + 1))
fi

echo
echo "════════════════════════════════════════════════════════════"
if [ "$fail" -eq 0 ]; then
  echo "  RECOVERY  ok  — filesystem matches STATE.md"
  echo "════════════════════════════════════════════════════════════"
  exit 0
else
  echo "  RECOVERY  $fail drift(s) detected"
  echo "════════════════════════════════════════════════════════════"
  echo "$report"
  exit 1
fi
