# API Contract Tests

> Each test is a black-box round-trip against the preview URL. Public traffic to `/api/*` on the preview hits Vercel SSO first (returns 401). To verify the *actual* function response, run with `vercel curl` (which injects `x-vercel-protection-bypass`).
>
> All tests assume the preview is at the URL set in `harness/scripts/smoke.sh` (override with `PREVIEW_URL=...` env var).

## T01. POST /api/contact with a valid body returns 200 with `{message}`

- **Expected:** HTTP 200, body `{"message":"Logged. I read these in the Vercel function log when I check the deploy. For anything time-sensitive, write directly to sachin@a-anie.example."}`.
- **Codifies:** D001 (honest messaging), D007 (log-only handler, honest 200 message), F003, F011.
- **Command:**
  ```bash
  vercel curl "$PREVIEW_URL/api/contact" \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{"name":"Smoke Test","email":"smoke@example.com","topic":"Feedback","message":"This is a 30-character message body for testing."}'
  ```
- **Pass condition:** status is exactly 200; body is parseable JSON with a `message` field that contains "Logged" or "sachin@a-anie.example".
- **Fail condition:** any other status; or 200 with `error` field; or 200 with the *old* message ("Sachin will reply soon") — that is a regression to D007.

## T02. POST /api/contact with an invalid email returns 400

- **Expected:** HTTP 400, body `{"error":"Please enter a valid email."}`.
- **Codifies:** D001.
- **Command:**
  ```bash
  vercel curl "$PREVIEW_URL/api/contact" \
    -X POST -H "Content-Type: application/json" \
    -d '{"name":"Smoke","email":"not-an-email","topic":"Feedback","message":"This is a 30-character message body for testing."}'
  ```
- **Pass condition:** status is 400; body has `error` matching the exact string.
- **Fail condition:** status is 200 (the handler is not validating); or 500 (unhandled throw).

## T03. POST /api/transcribe returns 501 with the honest "not deployed" message

- **Expected:** HTTP 501, body `{"ok":false,"error":"Transcription endpoint is not deployed..."}`.
- **Codifies:** D001, F004.
- **Command:**
  ```bash
  vercel curl "$PREVIEW_URL/api/transcribe" \
    -X POST -F "audio=@harness/tests/fixtures/silence.webm"
  ```
- **Pass condition:** status is 501; body has `ok:false`; `error` contains "not deployed" or "on-device".
- **Fail condition:** status is 200 (would mean a fake transcript is being returned — a hard no per D001).

## T04. POST /api/auth/signup returns 501 with the honest "Signup is not enabled yet" message

- **Expected:** HTTP 501, body `{"ok":false,"error":"Signup is not enabled yet..."}`.
- **Codifies:** D001, F004.
- **Command:**
  ```bash
  vercel curl "$PREVIEW_URL/api/auth/signup" \
    -X POST -H "Content-Type: application/json" \
    -d '{"email":"smoke@example.com","password":"correct-horse-battery-staple","name":"Smoke"}'
  ```
- **Pass condition:** status is 501; `error` contains "Signup" and "not enabled".

## T05. POST /api/auth/verify-otp returns 501

- **Expected:** HTTP 501, body `{"ok":false,"error":"Code verification is not enabled yet..."}`.
- **Codifies:** D001, F004.
- **Command:**
  ```bash
  vercel curl "$PREVIEW_URL/api/auth/verify-otp" \
    -X POST -H "Content-Type: application/json" \
    -d '{"email":"smoke@example.com","code":"123456"}'
  ```
- **Pass condition:** status is 501; `error` contains "verification" and "not enabled".

## T06. POST /api/auth/login returns 501

- **Expected:** HTTP 501, body `{"ok":false,"error":"Login is not enabled yet..."}`.
- **Codifies:** D001, F004, D004.
- **Command:**
  ```bash
  vercel curl "$PREVIEW_URL/api/auth/login" \
    -X POST -H "Content-Type: application/json" \
    -d '{"email":"smoke@example.com","password":"any-password"}'
  ```
- **Pass condition:** status is 501; `error` contains "Login" and "not enabled".

## T07. GET /api/auth/login returns 405 Method Not Allowed

- **Expected:** HTTP 405, `Allow: POST` header, body `{"ok":false,"error":"Method not allowed"}`.
- **Codifies:** D001.
- **Command:**
  ```bash
  vercel curl -I "$PREVIEW_URL/api/auth/login"
  ```
- **Pass condition:** status is 405; `Allow` header includes `POST`.

## T08. The auth stubs use `{ok, error}` shape; the contact handler uses `{error, message}` shape

- **Expected:** Auth stubs (T04-T07) return `{ok:false, error:"..."}`. Contact handler (T01, T02) returns `{error:"..."}` on failure and `{message:"..."}` on success.
- **Codifies:** the contract difference that F003 and F004 already note.
- **Pass condition:** all of T01-T07 pass; the contact handler never returns `{ok:...}` (a future refactor that "unifies" the shape must be rejected if it loses information).

## What "all pass" looks like

```text
T01  PASS  POST /api/contact valid  → 200
T02  PASS  POST /api/contact bad email → 400
T03  PASS  POST /api/transcribe → 501
T04  PASS  POST /api/auth/signup → 501
T05  PASS  POST /api/auth/verify-otp → 501
T06  PASS  POST /api/auth/login → 501
T07  PASS  GET  /api/auth/login → 405
T08  PASS  Shape contract preserved
```

If any test fails, the smoke script returns non-zero and the harness's verification agent does not declare "done".
