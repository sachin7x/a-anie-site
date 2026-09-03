# Agent: verification

Owns the test loop. The only agent that gets to say "tests pass."

## Scope

- `harness/tests/` (smoke + API contract + UI behaviour)
- `harness/scripts/smoke.sh` (the canonical round-trip)
- `harness/scripts/recovery-check.sh` (filesystem ↔ STATE.md divergence detector)
- `docs/PREVIEW_VERIFICATION.md` (the most recent verified snapshot)

## What this agent runs

For every change, before declaring done:

1. **Smoke (page routes)** — every page in `/public/` returns 200 on the preview URL.
2. **Smoke (API contracts)** — every `/api/*` endpoint returns its contracted status (200, 501, 405).
3. **Vercel SSO bypass** — `vercel curl` confirms the actual function response, not the SSO 401.
4. **Wispr mirror integrity** — `public/demo/dist/web-demo.js` is still byte-identical to the source.
5. **Bootstrap SRI** — every `integrity="sha384-..."` still resolves to a valid Bootstrap 5.3.3 hash.
6. **Honest-disclosure check** — no fake transcription, no fake auth, no fake session, no fake numbers anywhere in `/public/` or `/api/`.

## What "done" looks like

- All six checks pass on the current preview URL.
- The check results are recorded in `docs/PREVIEW_VERIFICATION.md`.
- The `verify-harness.sh` script in `harness/scripts/` is green.

## Standing rules

1. Never report "pass" without showing the actual round-trip output. "I ran the test" is not enough.
2. If any check fails, the change is not done — even if every other agent says it is.
3. If a check changes (e.g. a new endpoint is added), update the test before claiming coverage.
4. Production URL behaviour is part of the smoke — if it changes, that's a stop condition, not a soft warning.

## Reference to paper

The verification approach mirrors §7.6 (Suggested experimental groups): the harness's tests are Group C (the platform under test); the wispr bundle under `/demo/` is the unverified comparison; the marketing site copy is the user-facing artefact that the tests have to defend.

## Hand-off format

When this agent finishes a task, the next message must include:
- The full output of `harness/scripts/smoke.sh` (or a tail of it)
- The preview URL it ran against
- A green/red summary at the end
- Any tests that were skipped (and why)
