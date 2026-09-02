# Preview Deployment Verification — 2026-09-03

## Preview URL
`https://a-anie-site-raqw1co8r-sachin7xs-projects.vercel.app`

(Each commit redeploys to a new preview URL; the canonical preview
link is the most recent deploy. The list of historical previews is
in the commit log: 86e6845 → oh3u9ct9p, e5cbddc → dzygm0ymw,
769f609 → no preview (docs only), 3fec3b2 → raqw1co8r.)

This is a preview deploy from the `main` branch (commit `86e6845`).
Production URL `https://aanie-frontend.vercel.app/` is **not** touched.

## Page routes (30 paths)

All 30 page routes return **200** on the preview (with `vercel curl`
bypassing the Vercel SSO protection that public traffic hits):

| Path | Status |
|---|---|
| `/`, `/index.html` | 200 |
| `/app`, `/app.html` | 200 (the new wispr-style dictation entry) |
| `/demo/`, `/demo/index`, `/demo/web-demo` | 200 (preserved wispr mirror) |
| `/demo/login`, `/demo/signup`, `/demo/pricing` | 200 |
| `/login`, `/login.html` | 200 |
| `/signup`, `/signup.html` | 200 |
| `/how-it-works`, `/how-it-works.html` | 200 |
| `/pricing`, `/pricing.html` | 200 |
| `/story` | 200 |
| `/data-controls` | 200 |
| `/security` | 200 |
| `/accessibility`, `/careers`, `/support`, `/changelog` | 200 |
| `/contact`, `/terms` | 200 |
| `/demo/dist/web-demo.js` (23,666 bytes) | 200 — wispr bundle byte-identical |

## API routes (5 stubs)

All 5 serverless functions are deployed and reachable on the preview.
Vercel SSO returns 401 to public traffic; bypass via `vercel curl` shows
the actual function responses:

| Endpoint | Method | Response |
|---|---|---|
| `/api/transcribe` | POST (multipart) | **501** `{ok:false, error:"Transcription endpoint is not deployed..."}` |
| `/api/auth/signup` | POST (JSON) | **501** `{ok:false, error:"Signup is not enabled yet..."}` |
| `/api/auth/verify-otp` | POST (JSON) | **501** `{ok:false, error:"Code verification is not enabled yet..."}` |
| `/api/auth/login` | POST (JSON) | **501** `{ok:false, error:"Login is not enabled yet..."}` |
| `/api/contact` | POST (JSON) | **200** `{message:"Message sent. Thanks — Sachin will reply soon."}` |
| `/api/auth/login` | GET | **405** `{ok:false, error:"Method not allowed"}` |

## Login form round-trip (new in 3fec3b2)

`public/login.html` previously had a submit button with no JS handler
(the form would have done a default browser POST and reloaded the
page). The new handler:

- `login-form` submit → POST `/api/auth/login` with `{email, password}`
- `register-form` submit → POST `/api/auth/signup` with `{email, password, name}`

Both handlers render the verbatim backend response. Three branches:
- 401 → "Preview is behind Vercel SSO (401). The {endpoint} is not
  deployed; the page just hit the deployment-protection layer first."
- 501 / `{ok:false, error:"..."}` → verbatim `error` string
- Network error → "Network error. Email sachin@a-anie.example to be
  notified when signup is live."

No fake success, no fake session, no silent fallback.

## Frontend ↔ API contract

- `app.html` posts a recorded `audio/webm` blob to `/api/transcribe`.
  The `sendForTranscription()` function reads the `{ok:false, error}`
  shape and surfaces the verbatim error string in the transcript box
  as the "Backend not deployed" status. No fake transcription.
- `login.html` (placeholder) does not currently call `/api/auth/login`
  in JS — the form has no submit handler. The API stub is present for
  when the front-end gets wired up.
- `signup.html` posts `{email, code}` to `/api/auth/signup` then
  `/api/auth/verify-otp`. Both return 501 with the honest "not enabled
  yet" message. The form already renders that message on failure.
- `contact.html` posts `{name, email, topic, message}` to `/api/contact`
  and reads `{message}` on success. Round-trips end-to-end on the
  preview (verified 200 above).

## What was added in this deploy

- `public/app.html` (new) — Wispr-style push-to-talk dictation entry
  in the A-Anie shell. Real `getUserMedia` + `AnalyserNode` waveform,
  Space-to-record, posts to `/api/transcribe` (501). 23,436 bytes.
- `api/auth/login.js` (new) — 501 stub matching the auth shape.
- Nav patches on all 14 HTML pages (additive "App" link in header
  and/or footer; no copy edits, no removals).

## Honest-disclosure checks

- The `/app` page does not modify the wispr `/demo/` mirror or any
  wispr bundles. The IIFE is preserved; the A-Anie shell wraps it.
- No fake transcription, no fake auth, no fake session. Every
  surface that needs a backend returns 501 with a verbatim message
  the user can read.
- "On-device" / "private" copy is unchanged on the marketing pages.
- The contact form is the only form with a real (200) success path;
  the rest of the API surface is honest 501.

## Known limitation (Phase 6 open)

The preview deploy is behind Vercel SSO; public traffic hitting
`/api/*` gets a 401 "Protected deployment" instead of the 501 stubs.
Verified via `vercel curl` that the stubs themselves are reachable
and correctly shaped. Fixing this is Phase 6 (configure deployment
protection at the project level to allow public access to the
preview, or document the limitation honestly in the UI).
