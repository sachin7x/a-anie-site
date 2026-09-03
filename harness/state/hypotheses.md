# Hypotheses — Proposed, Not Validated

Each hypothesis is a claim this agent believes may be true but has not yet run a test for. Mark as HYPOTHESIS everywhere it appears. Promote to VERIFIED (in `facts.md`) or downgrade to UNKNOWN (in `open-questions.md`) only after the test runs.

## H001. The wispr bundle is functionally complete — adding new A-Anie surface does not need to extend it

- **PROPOSED:** 2026-09-03.
- **RATIONALE:** The wispr `/demo/` mirror (F002) and the inlined web-demo on `public/index.html` already implement the in-browser push-to-talk surface. The A-Anie shell wraps that surface rather than re-implementing it.
- **TO VERIFY:** Re-render the wispr surface on the live preview URL. Confirm that it captures mic, displays waveform, and (would) post to a transcription endpoint. If it does, the hypothesis is supported; if any of those fail, the wispr bundle is incomplete for our purposes and we need a parallel implementation.
- **CONFIDENCE:** MEDIUM (the byte-identical check confirms structure, not behaviour).
- **RELATED:** F002, I003.

## H002. The Vercel SSO gate is per-deploy, not per-project

- **PROPOSED:** 2026-09-03.
- **RATIONALE:** F006 says the preview deploy is gated but the production URL is not. If the SSO config were per-project, both would be affected. The split suggests the gate is per-deploy, applied automatically to non-production URLs.
- **TO VERIFY:** Check Vercel project settings for "Deployment Protection" scope. If the scope is "all non-production deployments", the hypothesis is supported; if it is "all deployments matching a path pattern", the gate is per-project.
- **CONFIDENCE:** MEDIUM.
- **RELATED:** F006, D003.

## H003. ~~The contact form's 200 success path is real end-to-end (not a stub that 200s)~~ — FALSIFIED, see F011

- **PROPOSED:** 2026-09-03.
- **FALSIFIED:** 2026-09-03.
- **EVIDENCE:** F011 — `api/contact.js` explicitly logs the payload and returns 200 without sending an email. The success message is misleading.
- **FOLLOWUP:** Update `/contact` UI to be honest. Email `sachin@a-anie.example` is the right address to surface, but the success branch should not promise "Sachin will reply soon" when no email is sent.
