# Facts — Directly Observed Evidence

Each fact is auditable: source, observation date, related test or file.

## F001. Bootstrap 5.3.3 CDN with SRI hashes

- **WHAT:** Every HTML page in `/public/` loads `bootstrap.min.css` and `bootstrap.bundle.min.js` from `cdn.jsdelivr.net` with `integrity="sha384-..."` SRI hashes.
- **SOURCE:** `grep "integrity" /Users/sachin/Pictures/ANNIE/public/*.html` (verified 2026-09-03).
- **STATUS:** VERIFIED.
- **CONFIDENCE:** HIGH.
- **RELATED TEST:** `scripts/smoke.sh` checks that pages 200 (a 200 with broken Bootstrap would still 200, so this is a structural check, not a behavioural one).

## F002. The wispr /demo/ mirror is byte-identical to the original

- **WHAT:** `public/demo/dist/web-demo.js` is 23,666 bytes. `public/demo/web-demo/index.js` is also 23,666 bytes. The first 80 bytes of `web-demo.js` are `"use strict";(()=>{var q=class{constructor(){this.mediaStream=null,this.mediaRec`.
- **SOURCE:** `wc -c` and `head -c 80` on the live files (2026-09-03).
- **STATUS:** VERIFIED.
- **CONFIDENCE:** HIGH.
- **RELATED TEST:** `/demo/dist/web-demo.js` returns 200 on preview with the same byte count.

## F003. /api/contact is a real handler (200)

- **WHAT:** POST `/api/contact` with valid `{name, email, topic, message}` returns `{message:"Message sent. Thanks — Sachin will reply soon."}` and HTTP 200.
- **SOURCE:** `vercel curl POST /api/contact` on preview `a-anie-site-raqw1co8r` (2026-09-03).
- **STATUS:** VERIFIED.
- **CONFIDENCE:** HIGH.
- **RELATED TEST:** see `harness/tests/api-contracts.md` test 1.

## F004. /api/transcribe, /api/auth/{signup,verify-otp,login} return 501

- **WHAT:** All four auth/transcription endpoints return HTTP 501 with `{ok:false, error:"..."}` body. The error string names the missing step (email delivery, session, on-device model).
- **SOURCE:** `vercel curl POST /api/{transcribe,auth/signup,auth/verify-otp,auth/login}` on preview (2026-09-03).
- **STATUS:** VERIFIED.
- **CONFIDENCE:** HIGH.
- **RELATED TEST:** see `harness/tests/api-contracts.md` tests 2-5.

## F005. Production URL is on an older deploy

- **WHAT:** `https://aanie-frontend.vercel.app/` returns 200 on `/`, but 404 on `/careers`, `/accessibility`, `/support`, `/changelog`, `/contact`, `/security`. The new pages (added in commits 86e6845+) are not on production. This is correct and intended: production is stable, new work goes to preview.
- **SOURCE:** `curl -I` on each path against the production hostname (2026-09-03).
- **STATUS:** VERIFIED.
- **CONFIDENCE:** HIGH.
- **RELATED TEST:** implicit — the absence of a 200 on the new pages is the test.

## F006. Vercel SSO gates /api/* on the preview

- **WHAT:** Public traffic to `https://a-anie-site-<hash>-...vercel.app/api/*` returns 401 with body `{"protection":{...},"error":{"code":"401","message":"Protected deployment"}}`. The `vercel curl` CLI bypasses the protection via `x-vercel-protection-bypass` header.
- **SOURCE:** `curl` vs `vercel curl` against the same URL (2026-09-03).
- **STATUS:** VERIFIED.
- **CONFIDENCE:** HIGH.
- **RELATED TEST:** documented in `docs/BUILD_STEPS.md` §"Verifying preview-deploy API stubs".

## F007. Contact form posts JSON with field "topic", reads `{message}` on success

- **WHAT:** `public/contact.html`'s form serializes the form as JSON with field name `topic` (renamed from `subject`). The success branch is `out.status >= 200 && out.status < 300 && out.j.message && !out.j.error`. The form was broken before commit 32322c7 — it posted FormData with field `subject` and read `out.j.ok`/`out.j.error`. Fixed.
- **SOURCE:** `git show 32322c7` (2026-09-03).
- **STATUS:** VERIFIED.
- **CONFIDENCE:** HIGH.
- **RELATED TEST:** manual round-trip via `vercel curl POST /api/contact` (test 1 in `harness/tests/api-contracts.md`).

## F008. /app's sendForTranscription() handles 501, 200, 401, network-error

- **WHAT:** `public/app.html` has four branches in the transcribe response handler: 501 (or `{error:"not_implemented"}`), 200 with `{text}`, 401 (Vercel SSO), and any other status. The 401 branch was added in commit e5cbddc to honestly surface the preview-protection layer instead of the generic "Network error" path.
- **SOURCE:** `git show e5cbddc` and the source of `public/app.html` (2026-09-03).
- **STATUS:** VERIFIED.
- **CONFIDENCE:** HIGH.
- **RELATED TEST:** `harness/tests/app-shell.md`.

## F009. login.html submit handler exists and posts to /api/auth/login and /api/auth/signup

- **WHAT:** `public/login.html` had a `<form id="login-form">` with a submit button but no JS handler before commit 3fec3b2. The handler now POSTs to `/api/auth/login` and `/api/auth/signup`, rendering the verbatim 501 error or the honest 401 message.
- **SOURCE:** `git show 3fec3b2` (2026-09-03).
- **STATUS:** VERIFIED.
- **CONFIDENCE:** HIGH.
- **RELATED TEST:** `harness/tests/api-contracts.md` test 6.

## F011. /api/contact is log-only, not a real email send

- **WHAT:** `api/contact.js` validates the body, then `console.log()`s the submission and returns 200 with `{message:"Message sent. Thanks — Sachin will reply soon."}`. The "In a real implementation you would send an email here" comment is explicit: the email step is not implemented.
- **SOURCE:** read of `api/contact.js` (2026-09-03).
- **STATUS:** VERIFIED.
- **CONFIDENCE:** HIGH.
- **RELATED TEST:** `harness/tests/api-contracts.md` test 1 still passes (200, valid body), but the user-facing message is misleading. Q002 closed; the success message on `/contact` and the API response both need to be honest about "logged, not emailed".
- **HYPOTHESIS STATUS:** H003 promoted to FACT — and the original hypothesis ("real email send") is now falsified.

## F010. "On-device" / "private" copy on marketing pages matches the architecture

- **WHAT:** `public/how-it-works.html` §"What runs on your Mac" and §"What A-Anie does not do" claim on-device processing and no cloud round-trip. The contact form's privacy section says the form is not encrypted in transit, security disclosures should not go through the form.
- **SOURCE:** read of `/Users/sachin/Pictures/ANNIE/public/how-it-works.html` (2026-09-03).
- **STATUS:** VERIFIED (the text exists; the architectural claim cannot be audited from this repo because the desktop app is external).
- **CONFIDENCE:** MEDIUM (text is in place; underlying claim depends on a binary that is not in this repo).
- **RELATED TEST:** out of scope for this repo. The marketing site can only assert what the desktop app actually does if a separate verification passes.
