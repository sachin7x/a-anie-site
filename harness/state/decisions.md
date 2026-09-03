# Decisions — Settled Design Choices

Each decision is dated, named, and points to the file/line that codifies it.

## D001. Honest 501 stubs, not fake 200s

- **DECIDED:** 2026-09-03.
- **WHAT:** Every `/api/*` endpoint that is not yet implemented returns 501 with `{ok:false, error:"<honest reason>"}`. The error names the missing step (email delivery, session, on-device model).
- **WHY:** The user constraint "do not fabricate" means no fake success. The user should always be able to read the reason the feature is missing.
- **CODIFIED IN:** `api/transcribe.js`, `api/auth/{signup,verify-otp,login}.js`.
- **SUPERSEDES:** none.
- **DEPRECATED BY:** none.

## D002. /app is a wispr-style push-to-talk dictation entry, not a real backend

- **DECIDED:** 2026-09-03.
- **WHAT:** `public/app.html` is a real getUserMedia + AnalyserNode + Space-to-record dictation UI. It posts audio to `/api/transcribe`, which is a 501 stub. The page surfaces the 501 / 401 / network-error honestly — no fake transcript.
- **WHY:** Demonstrates the contract end-to-end without shipping a real backend (which the user does not have today).
- **CODIFIED IN:** `public/app.html`, `api/transcribe.js`.
- **SUPERSEDES:** none.
- **DEPENDS ON:** D001.

## D003. Vercel SSO bypass via `vercel curl`, not at the project level

- **DECIDED:** 2026-09-03.
- **WHAT:** The preview deploy is behind Vercel SSO. Public traffic to `/api/*` returns 401 "Protected deployment". We do not disable SSO at the project level (because that affects the production URL's invariants). Instead, smoke tests use `vercel curl` to inject the bypass header.
- **WHY:** Production URL must never change. Project-level SSO config would change it. The CLI bypass is the official Vercel workflow.
- **CODIFIED IN:** `docs/BUILD_STEPS.md` §"Verifying preview-deploy API stubs".
- **SUPERSEDES:** none.
- **REVISIT IF:** the user provides project-level SSO scope controls (not currently exposed).

## D004. login.html submit handlers added (gap-fix)

- **DECIDED:** 2026-09-03.
- **WHAT:** `public/login.html` previously had submit buttons with no JS handler. Now both `login-form` and `register-form` POST to the auth stubs and render the verbatim response.
- **WHY:** Gap found in self-review. A submit button without a handler would have caused a default browser POST and reloaded the page — looks like a fake success.
- **CODIFIED IN:** `public/login.html` (the IIFE near the bottom of `<body>`).
- **SUPERSEDES:** none.
- **DEPENDS ON:** D001.

## D005. Marketing site is the on-device slice of the paper's architecture, not the full reference

- **DECIDED:** 2026-09-03.
- **WHAT:** A-Anie is the on-device slice of `guide.md`'s full architecture. No cloud, no LLM-refinement, no accounts, no billing, no auth flow. The marketing site is a static clone of the wispr surface; the desktop app (not in this repo) is the product.
- **WHY:** The user constraint "do not fabricate" forbids shipping fake features. The paper describes a *proposed* system; A-Anie ships only the parts that are real.
- **CODIFIED IN:** `public/how-it-works.html` §"What A-Anie does not do".
- **SUPERSEDES:** none.
- **REVISIT IF:** A-Anie's desktop app gains LLM refinement, accounts, or a cloud tier.

## D006. Architecture applied: paper components → A-Anie product

- **DECIDED:** 2026-09-03.
- **WHAT:** Map paper §4 components onto A-Anie (the desktop app). Client = Tauri/Rust; Streaming preprocessing = internal VAD; ASR = whisper.cpp (local); Text generation = light local cleanup, deliberately not an LLM; Personal vocab = local JSON; Output → active app = macOS accessibility API; Cloud = none. The auth/db/storage components from §4-5 of the paper are NOT in A-Anie.
- **WHY:** A-Anie is a one-developer on-device product. Cloud, accounts, billing are anti-features for this product shape. The mapping is honest and durable.
- **CODIFIED IN:** `harness/STATE.md` §"Architecture (applied from paper)".
- **SUPERSEDES:** none.
- **REVISIT IF:** A-Anie ships a cloud tier or a team/enterprise SKU.

## D007. /api/contact returns a log-only honest message, not "Sachin will reply soon"

- **DECIDED:** 2026-09-03.
- **WHAT:** The `/api/contact` response message now says "Logged. I read these in the Vercel function log when I check the deploy. For anything time-sensitive, write directly to sachin@a-anie.example." The handler is still log-only (F011); the user-facing string is now aligned with the actual behaviour.
- **WHY:** F011 shows the previous 200 message ("Sachin will reply soon") was a lie — the message was only `console.log`ged. The no-fabrication constraint (D001) requires that the user-facing string match the actual behaviour.
- **CODIFIED IN:** `api/contact.js`.
- **SUPERSEDES:** previous contact-handler success message.
- **REVISIT IF:** a real email-send step is added to the handler.
