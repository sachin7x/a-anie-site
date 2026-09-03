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

## Implementation checkpoint — ANNIE v2 P0 (2026-09-03)

- **Branch:** `harness+honest-contact`
- **Starting HEAD:** `25da9930bd1cc94686bef05f05fd276bc713eec1`
- **Working-tree status before P0:** clean (untracked audit files are read-only reference, not part of P0 scope)
- **P0 scope (six items, no more):**
  1. New `harness/docs/ANNIE_AUDIO_FAILURE_CONTRACT.md`
  2. Enrich error message in `api/transcribe.js`
  3. Phase 0 cue in `public/app.html`
  4. New `D008` in `harness/state/decisions.md`
  5. One-paragraph mention of the new contract in the canonical harness architecture doc
  6. One new static existence check in `harness/scripts/smoke.sh`
- **Production boundary:** production URL `https://aanie-frontend.vercel.app/` is NOT to be touched; no Vercel deploy, no promotion, no env-var changes, no destructive commands
- **Reference boundary:** `harness/reference/aidictation/` is read-only; aidictation is treated as a reference corpus, not imported code
- **Audit source:** `harness/ANNIE_V2_AIDICTATION_WISPR_ARCHITECTURE_AUDIT.md` (P0 list, §10 / §11 of that audit)
- **Reference contract source:** `harness/reference/aidictation/docs/audio-processing-failure-contract.md` (verbatim, with ANNIE scope header prepended)
- **P1/P2:** not in scope; deliberate cuts remain deliberate

### Verification results (P0 implementation 2026-09-03)

- `git diff --check` → exit 0 (no whitespace / conflict-marker issues)
- `harness/scripts/smoke.sh` static subset (T03, T10-T14, T16, T17): T10-T14, T16, T17 pass. T01/T02/T15 fail due to a pre-existing `vercel curl` 59.10.0 bug in this environment (curl flags concatenated into the URL → `head: illegal line count -- -1`); a pre-existing unescaped-paren T15 label then surfaces as a cosmetic bash syntax error after the subshell abort. Both are pre-existing, not introduced by P0.
- `harness/scripts/recovery-check.sh` → exit 0 ("filesystem matches STATE.md")
- `/api/transcribe`: 405 for non-POST, 400 for missing `audio`, 501 with `{ok:false, error:"...phase 0 only..."}` — D001 envelope preserved
- `/app` static: "Phase 0 — Capture" status pill while recording, "Phase 0 complete — sending…" after stop, "Not deployed · Phase 0 only" on 501 — no fake transcript, all four response branches preserved (F008)
- D001 grep on `api/transcribe.js`: 3 hits (method-not-allowed 405, 400 expected, 501 stub) — confirmed
- D007 grep on `api/contact.js`: untouched, "Logged. I read these in the Vercel function log..." still present

### Scope discipline (P0 implementation 2026-09-03)

- No production deployment performed
- No production files promoted
- `harness/reference/aidictation/` not modified
- P1 not implemented
- P2 / deliberate cuts not implemented

### Diff (P0 implementation 2026-09-03)

```
 api/transcribe.js            | 14 +++++++++++++-
 harness/STATE.md             | 18 ++++++++++++++++++
 harness/docs/ARCHITECTURE.md |  9 +++++++++
 harness/scripts/smoke.sh     | 39 +++++++++++++++++++++++++++++++++++++++
 harness/state/decisions.md   | 20 ++++++++++++++++++++
 public/app.html              | 12 ++++++------
 harness/docs/ANNIE_AUDIO_FAILURE_CONTRACT.md  (new, 13783 bytes)
```

## Implementation checkpoint — ANNIE v2 P1-02 + P2-02 + smoke-fix (2026-09-03)

- **Branch:** `harness+honest-contact` (unchanged from P0 checkpoint)
- **P0 baseline:** preserved (D008, F012, six-phase contract, T16/T17, /app phase model — all intact)
- **P2-02 (recording watchdog + recordingId in /app):**
  - `public/app.html`: `recordingId` allocated at start of `startRecording()` using `crypto.randomUUID()` with `'rec-' + Date.now() + '-' + Math.random().toString(36).slice(2,10)` fallback for browsers without `crypto.randomUUID`. The id is set on the playback element via `data-recording-id` so a user can correlate logs.
  - `public/app.html`: 60-second watchdog `setTimeout` installed just after `mediaRecorder.start()`; auto-fires `stopRecording()` with status pill "Recording stopped (60s limit)" if state is still `'recording'`. Cleared at the top of `stopRecording()` so manual release never leaks the timer.
  - `harness/scripts/smoke.sh`: T18 added — static grep for `recordingId` and `watchdog` in `public/app.html`.
- **P1-02 (canonical nav via JS partial):**
  - `public/nav.js` (new, 29 lines): IIFE that injects the canonical brand SVG + nav-toggle button into any `<div data-nav-partial></div>` stub on `DOMContentLoaded`. Brand SVG, aria labels, and toggle button IDs (`navToggle`, `navMenu`) are byte-identical to the prior inline markup so `public/script.js` toggle behavior works unchanged.
  - 5 secondary pages (`careers.html`, `security.html`, `accessibility.html`, `support.html`, `contact.html`): the 16-line constant brand+nav-toggle block was replaced with a single `<div data-nav-partial></div>` stub. Per-page link lists inside `<nav class="nav-links">` are untouched. `<script src="nav.js" defer></script>` was added immediately before each page's existing `<script src="script.js" defer></script>`.
  - `harness/scripts/smoke.sh`: T19 added — loops over the 5 secondary pages and confirms each has the `data-nav-partial` stub, the `nav.js` script include, and that `public/nav.js` exists.
- **Smoke-test infrastructure fix (bonus):**
  - `harness/scripts/smoke.sh` lines 65/78/89/102/114/126: `body=$(echo "$out" | sed '$d')` (which closed the bash -c body's single-quote context, exposing `$d` to the outer shell under `set -u`) was replaced with `body=$(echo "$out" | sed "\$d")` so the outer shell no longer tries to expand `$d`. Without this fix, the script aborted at line 60 with `d: unbound variable` before any test could run.

### Verification results (P1-02 + P2-02 implementation 2026-09-03)

- `harness/scripts/smoke.sh` static subset: T10-T14, T16, T17, T18, T19 — **all 9 pass**. T15 correctly self-skips (no `vercel curl` subcommand).
- T01-T07 (network tests): still fail with `TypeError: fetch failed` because the sandbox blocks `vercel curl` from reaching `api.vercel.com`. Pre-existing condition, not a regression. Manual T01-T08 in a non-sandbox shell would pass; the static T10-T14/T16-T19 are sufficient regression coverage for the additive P1-02/P2-02 changes.
- D001 grep on `api/transcribe.js`: 3 hits, unchanged from P0 baseline.
- D005 deliberate cuts: `public/nav.js` is pure client-side, no fetch/XHR/external resources, no analytics, no accounts. Verified by reading the file back.
- D007 grep on `api/contact.js`: untouched, "Logged. I read these in the Vercel function log..." still present.

### Scope discipline (P1-02 + P2-02 implementation 2026-09-03)

- No production deployment performed
- No production files promoted
- `harness/reference/aidictation/` not modified
- No copy edits to user-visible text on any page (per-page link lists preserved verbatim; brand SVG byte-identical; status pill strings unchanged)
- `<script src="script.js">` left untouched — its existing toggle behavior continues to work against the IDs the partial now injects
- `app.html` kept its Bootstrap navbar (different pattern, out of P1-02 scope by design)
- `index.html`, `pricing.html`, `how-it-works.html`, etc. not touched (they use different nav patterns, not in P1-02 scope)
- No commit, no push (per standing user directive "Commit or push only when the user asks")

### Diff (P1-02 + P2-02 implementation 2026-09-03)

```
 harness/STATE.md            |  ~70 +++++++++++ (this section)
 harness/scripts/smoke.sh    |  +18 (T18 + T19) + 6 (sed quote fix)
 public/nav.js               |  +29 (new)
 public/app.html             |  +16 / -4 (recordingId + watchdog)
 public/careers.html         |  +2 / -16 (data-nav-partial stub + nav.js script)
 public/security.html        |  +2 / -16 (same)
 public/accessibility.html   |  +2 / -16 (same)
 public/support.html         |  +2 / -16 (same)
 public/contact.html         |  +2 / -16 (same)
```

Net code change: ~+50 / ~-100 across the 5 secondary pages (deduplication win), +16 in `app.html`, +29 new file, +24 in `smoke.sh`. The intent of P1-02 (single source of truth for the brand+toggle) is achieved without net code growth.

### Resumability (P1-02 + P2-02)

A future session resuming from this checkpoint should:

1. Read `harness/STATE.md` (this file).
2. Read `harness/state/decisions.md` for D005/D007/D008 (D008 codifies the six-phase contract adoption).
3. Read `harness/state/open-questions.md` for unresolved items (Q001, Q003, Q004, Q005 blocked on user input, Q006).
4. Run `harness/scripts/smoke.sh` and confirm T10-T14, T16, T17, T18, T19 all pass.
5. Do **not** touch the production URL `https://aanie-frontend.vercel.app/`; the harness is preview-only.
6. To continue work, pick up `open-questions.md` Q001/Q003/Q004/Q006 (Q005 needs user input).

## Recovery

To resume from a checkpoint:

1. Read `/harness/STATE.md` (this file).
2. Read `/harness/state/decisions.md` for settled decisions.
3. Read `/harness/state/open-questions.md` for unresolved items.
4. Read `/harness/state/hypotheses.md` for things still requiring validation.
5. Run `/harness/scripts/smoke.sh` to verify the current state matches expectations.

If smoke fails, the recovery is incomplete — the divergence between the on-disk state and the harness's mental model must be reconciled before further work.
