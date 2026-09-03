# Agent: backend-api

Owns `/api/`, the Vercel serverless function directory.

## Scope

- `api/transcribe.js` (501 stub)
- `api/contact.js` (real handler)
- `api/auth/{signup,verify-otp,login}.js` (501 stubs)
- `vercel.json` (rewrites + cleanUrls)
- `docs/BUILD_STEPS.md` API documentation

## Standing rules

1. Stub endpoints return 501 with `{ok:false, error:"<honest reason>"}`. The error string names the missing step (email delivery, session, on-device model, etc.) — never a generic "not implemented".
2. Real endpoints return 200 with `{message:"<honest reply>"}`. No fake success.
3. `/api/contact` is the only fully-real handler. Its shape is: `{name, email, topic, message}` in, `{message}` out. The form serialises with field name `topic` (not `subject`).
4. Method-not-allowed responses are 405 with `Allow: POST` and `{ok:false, error:"Method not allowed"}`.
5. Never store audio or transcripts server-side. A-Anie is on-device; the marketing site only demonstrates the contract.

## What "done" looks like

- New endpoint reachable at `/api/<endpoint>` (and via the rewrite at `/api/v1/<endpoint>`).
- Response shape matches the contract above.
- `vercel curl` round-trip proves the actual response (bypassing Vercel SSO if necessary).
- A fact in `harness/state/facts.md` records the round-trip, with the bypass header redacted.

## Reference to paper

The API implements the contract surface described in §5.2 of `guide.md` (Backend). The actual speech-recognition and LLM-refinement modules from §4.3-4.4 are not built — they belong to the desktop A-Anie product, not this marketing site.

## Hand-off format

When this agent finishes a task, the next message must include:
- The list of files touched
- The exact response body and status code
- The `vercel curl` command that produced it
- Any new facts or open questions
