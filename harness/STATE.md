# ANNIE Harness — Project Memory

> Living document. This is the harness's persistent state, not a journal.
> Each entry is the agent's current best knowledge, not a historical log.
> Historical observations go in `observations/`.

## Identity

- **Product:** A-Anie — solo-built on-device dictation app (macOS, whisper.cpp, 6 Indian languages).
- **Marketing site repo:** `/Users/sachin/Pictures/ANNIE/`
- **Production URL:** `https://aanie-frontend.vercel.app/` (load-bearing, must never be down)
- **Preview URL pattern:** `https://a-anie-site-<hash>-sachin7xs-projects.vercel.app/`
- **Author:** Sachin Dohdiya, Kishangarh. One developer, no company, no team.

## Reconstructed surface (the wispr clone, scoped by the existing mirror)

The site is the reconstruction. Routes and APIs:

| Route | Type | Source of truth | Status |
|---|---|---|---|
| `/` | landing | A-Anie (custom) | 200 prod, 200 preview |
| `/app` | in-browser dictation | A-Anie (wispr-style) | preview only, 200 |
| `/app.html` | same | — | 200 |
| `/demo/` | wispr mirror (research artifact) | byte-identical wispr bundles | 200, untouched |
| `/login`, `/signup` | auth forms | A-Anie (placeholder) | 200 |
| `/how-it-works`, `/pricing`, `/story`, etc. | marketing | A-Anie | 200 prod/404 prod depending on deploy |
| `POST /api/transcribe` | transcription | 501 stub | deployed, 501 |
| `POST /api/contact` | contact form | real handler | 200 |
| `POST /api/auth/signup` | auth | 501 stub | 501 |
| `POST /api/auth/verify-otp` | auth | 501 stub | 501 |
| `POST /api/auth/login` | auth | 501 stub | 501 |

## Standing user constraints (apply to every agent action)

1. "do not delete content from site only focus on UI" — additive only.
2. "nothing should be changes than css from old font" — minimal copy edits.
3. "do not fabricate" — no fake transcription, auth, sessions, accuracy numbers, latency numbers, claims.
4. "I dont want cheap illustrations" — no AI imagery of fake people/products.
5. "This is the main URL, this should never be down" — production never touched.
6. "Keep all the content the same, everything the same" — no copy edits.
7. "preview only" — new work ships to preview URL, not production.

## Architecture (applied from paper + Prime Agent ideas)

The paper's reference architecture (client → preprocessing → ASR → context-aware text gen → personal vocab → formatted output → active app, plus auth/persistence/privacy) is applied to the **desktop A-Anie product**, not the marketing site. The marketing site is a static clone of the wispr surface; the architecture below is the *product* A-Anie should converge on.

| Paper component | Where it lives in A-Anie | State |
|---|---|---|
| Client (Tauri/Rust desktop) | A-Anie.app, not in this repo | external |
| Streaming audio preprocessing | A-Anie internal (VAD, silence trim) | VERIFIED (how-it-works.html §"Silence trim") |
| ASR (whisper.cpp) | A-Anie internal | VERIFIED |
| Context-aware text generation | A-Anie internal cleanup pass (light, not LLM) | VERIFIED (deliberately NOT an LLM per marketing copy) |
| Personal vocabulary | A-Anie local JSON file | VERIFIED |
| Formatted output → active app | A-Anie text injection (accessibility API) | VERIFIED |
| Cloud backend | NOT in A-Anie (on-device only) | VERIFIED (deliberate decision) |
| Auth (OAuth/JWT/SSO) | NOT in A-Anie (no accounts today) | VERIFIED (no-accounts product) |

**Honest mapping:** A-Anie is the on-device slice of the paper's architecture, without the cloud, without the LLM, without accounts, without billing. That is a deliberate product decision documented in `how-it-works.html` ("What A-Anie does not do"). The marketing site is the visible surface; the desktop app is the actual product.

## Agent hierarchy (minimal, from user's preferred sketch)

```
Root Reconstruction Agent (this session)
  ├── evidence-research   — owns /harness/state/facts.md, observations
  ├── frontend-reconstruction — owns /public/, /public/app.html
  ├── backend-api        — owns /api/
  ├── behavioral-test    — owns /scripts/, /harness/tests/
  └── verification       — owns the smoke test loop
```

Specialization is by file ownership, not by separate Claude processes. A single Claude session can play multiple roles; the file ownership keeps the responsibilities separate.

## Recovery

To resume from a checkpoint:

1. Read `/harness/STATE.md` (this file).
2. Read `/harness/state/decisions.md` for settled decisions.
3. Read `/harness/state/open-questions.md` for unresolved items.
4. Read `/harness/state/hypotheses.md` for things still requiring validation.
5. Run `/harness/scripts/smoke.sh` to verify the current state matches expectations.

If smoke fails, the recovery is incomplete — the divergence between the on-disk state and the harness's mental model must be reconciled before further work.
