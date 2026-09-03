# Inferences — Derived from Facts

Each inference is a chain from one or more VERIFIED facts in `harness/state/facts.md` plus a stated reasoning step. Mark INFERRED claims as such everywhere they appear in the harness.

## I001. The 4 production-404 pages are deliberately stable, not a regression

- **FROM:** F005 (production URL serves only the pre-existing pages; the new pages 404).
- **CHAIN:** F005 says the new pages (careers, accessibility, support, changelog, contact, security) are not on the production deploy. F005 is VERIFIED via `curl -I` on each path. The 404s are therefore the *expected* state, not a regression: production is pinned to an older deploy, and new work goes to preview.
- **CONFIDENCE:** HIGH.
- **IMPLICATIONS:** Any change to the production URL's behaviour would be a stop condition. The harness does not test the production URL's page completeness — it only tests that it is up and that the 200-paths still 200.

## I002. /app's sendForTranscription reaches a 401 on the preview, not the 501 it expects

- **FROM:** F006 (Vercel SSO gates /api/* on the preview) + F008 (the 401 branch in the response handler).
- **CHAIN:** A user loading `/app` on the preview URL will hit the SSO 401 path, not the 501 path. The 401 branch (added in e5cbddc) is the path the public user actually sees; the 501 path is what `vercel curl` confirms the stub returns.
- **CONFIDENCE:** HIGH.
- **IMPLICATIONS:** The 401 message ("Preview is behind Vercel SSO. The transcription endpoint is not deployed; the page just hit the deployment-protection layer first.") is the message the public user reads. Keep that message accurate; the 501 message ("Backend not deployed.") is what the bypass-user reads.

## I003. The wispr /demo/ mirror's "byte-identical" claim is a structural guarantee, not a behavioural one

- **FROM:** F002 (byte count and first-80-bytes match between `public/demo/dist/web-demo.js` and the source).
- **CHAIN:** A byte-equality check confirms the file on disk matches the source. It does *not* confirm that the source is what Wispr shipped — for that, a separate verification against the upstream bundle would be needed. The byte check is structural; the upstream-claim would be behavioural.
- **CONFIDENCE:** MEDIUM (the on-disk bytes match; the on-disk-source-claim is asserted in `docs/WISPR_TO_ANNIE_HOW_IT_WORKS.md` but is not independently re-verified here).
- **IMPLICATIONS:** The wispr mirror is a research artifact and a reference. The marketing site uses it as a *visual* reference for the inlined web-demo. The byte check is sufficient to confirm "this is the same as what's on disk." A different verification is needed to confirm "what's on disk is what Wispr shipped."

## I004. "On-device" / "private" copy is honest today, contingent on the desktop app's behaviour

- **FROM:** F010 (the marketing copy is in place; the underlying claim is in the desktop app, not in this repo).
- **CHAIN:** The marketing site can only assert what its own code does. The claim "audio never leaves your Mac" is a property of the desktop A-Anie binary. The marketing site should not assert properties it cannot verify itself.
- **CONFIDENCE:** MEDIUM (text is in place; underlying claim is in code we cannot audit from this repo).
- **IMPLICATIONS:** If the user later asks "is the on-device claim true?", the answer is "this repo cannot verify that — the desktop app's behaviour would need a separate test." Do not assert the claim as a VERIFIED fact from this repo's evidence alone.
