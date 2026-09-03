# A-Anie Frontend — Project Agentic Directive

> Marketing site + static asset surface for [a-anie-site](https://github.com/sachin7x/a-anie-site).
> Canonical memory: [`harness/STATE.md`](harness/STATE.md). Standing facts: [`harness/state/facts.md`](harness/state/facts.md). Decisions: [`harness/state/decisions.md`](harness/state/decisions.md). Read those before changing anything substantive.

## Standing user constraints (do not relax without asking)

1. **The canonical URL must never go down.** `https://aanie-frontend.vercel.app/` is the production marketing URL. Every change goes to a preview first; main is deployed only after preview verification. See `docs/BUILD_STEPS.md`.
2. **Do not delete content from the site.** Only CSS, layout, and assets may change. All copy, headings, and section bodies are preserved verbatim. See D001 (no fabrication) and the build steps.
3. **No fabrication.** No fake numbers, testimonials, competitor specs, sample transcripts, "Welcome back, John!"-style fabricated greetings, or pretend-success flows. If a copy slot needs content, write the honest default (e.g. "Logged. I read these in the Vercel function log."). Codified in D001 + D007.
4. **Honest 501 over fake 200.** Stub endpoints return `501 Not Implemented` with `{ok:false, error:"<honest reason>"}`. Real endpoints return `200` with `{message:"<honest reply>"}`. The shape never fakes a successful action.
5. **Vercel SSO bypass is at the curl layer, not the project layer.** `vercel curl` injects `x-vercel-protection-bypass`. The project keeps its protection on; we don't disable it account-wide. D003.
6. **Use more agents, not less.** Parallelize; do not block the user with 2-hour waits. See `harness/agents/00-root.md` for the recovery loop.
7. **Preview URL only deployment.** No direct-to-main push without preview verification.

## Architecture

- 15 static HTML pages in `public/` (14 Bootstrap-pinned + `terms.html`, a Bootstrap-free legal document), served by Vercel with `cleanUrls: true` and `/api/v1/:path*` → `/api/:path*` rewrite (see `vercel.json`).
- 5 serverless functions in `api/`: `contact.js` (log-only, D007) and 4 auth/transcribe stubs returning 501 (D001).
- Bootstrap 5.3.3 from jsDelivr CDN with SRI hash pinned on every page that loads it (F001). `terms.html` is a legal document and intentionally does not load Bootstrap.
- A wispr-style `/demo/dist/web-demo.js` mirror (F002, 23,666 bytes, byte-identical to upstream) for research provenance.
- `/app` (and `/app.html`) is a wispr-style push-to-talk dictation entry that demonstrates the real product surface without a real backend. It reaches `/api/transcribe`, which returns 501 on preview (D002).
- Voice-dictation paper architecture is mapped onto the product in [`harness/docs/ARCHITECTURE.md`](harness/docs/ARCHITECTURE.md); aidictation (WhisperMate) reference is in [`harness/docs/REFERENCE_MAP.md`](harness/docs/REFERENCE_MAP.md).

## Agent specs (read before changing scope)

- [`harness/agents/00-root.md`](harness/agents/00-root.md) — orchestrator, owns the recovery loop.
- [`harness/agents/01-frontend.md`](harness/agents/01-frontend.md) — owns `public/`.
- [`harness/agents/02-backend.md`](harness/agents/02-backend.md) — owns `api/` and `vercel.json`.
- [`harness/agents/03-evidence.md`](harness/agents/03-evidence.md) — owns `harness/state/`.
- [`harness/agents/04-verification.md`](harness/agents/04-verification.md) — runs the test suite, never claims pass without output.

## Verification

- [`harness/scripts/smoke.sh`](harness/scripts/smoke.sh) — API contract + app-shell smoke against the preview URL. Override: `PREVIEW_URL=... ./smoke.sh`. Requires `vercel` CLI for full coverage; static checks still run without it.
- [`harness/scripts/recovery-check.sh`](harness/scripts/recovery-check.sh) — filesystem ↔ STATE.md drift detector. Run after any change to `public/`, `api/`, or `harness/state/`.
- [`harness/tests/api-contracts.md`](harness/tests/api-contracts.md) and [`harness/tests/app-shell.md`](harness/tests/app-shell.md) — what the smoke is supposed to check.

## When to update the harness

- A new page is added → update `harness/state/facts.md` (F0xx), `harness/scripts/recovery-check.sh` (core-structure check), and the agent spec in `harness/agents/01-frontend.md`.
- A new API endpoint is added → update `harness/state/facts.md` and the API-contract tests.
- A decision is made that future agents need to honour → write it to `harness/state/decisions.md` as D00x with a failure-mode comment and a delete trigger.
- A new fact is observed → write it to `harness/state/facts.md` with the source (path + line, or external URL) and the date observed.
- A fact turns out to be wrong → move it to `harness/state/inferences.md` or `harness/state/hypotheses.md` with the falsification evidence, never silently delete.

## What NOT to do here

- Do not commit secrets, environment variables, or `.env*` files. The repo has no `.env`; if you need one, the user's local is the source of truth.
- Do not add a build step, a framework, or a bundler. The site is intentionally static. See D005 for the deliberate-cuts list.
- Do not add Windows / Android / iOS native build references to this repo. The desktop app is a separate repository.
- Do not disable Vercel SSO at the project level. Bypass only via `vercel curl` locally.
- Do not push directly to `main`. Use the preview-URL-only deployment flow.

## Provenance

This directive is informed by the voice-dictation reference paper at `harness/docs/guide.md` and `guide2.md`, the paper-to-product architecture map at `harness/docs/ARCHITECTURE.md`, the aidictation reference map at `harness/docs/REFERENCE_MAP.md`, and the open-source cousin at `harness/reference/aidictation/` (MIT-licensed; read-only).
