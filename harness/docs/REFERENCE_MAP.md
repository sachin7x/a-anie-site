# Reference Map — `aidictation` → A-Anie

> Reference: `harness/reference/aidictation/` (shallow clone of https://github.com/writingmate/aidictation, MIT-licensed).
>
> aidictation ("WhisperMate") is the open-source cousin of A-Anie. Same product shape (cross-platform voice-to-text), different build choices. This file records which aidictation choices we copy, which we deliberately cut, and which patterns we are still deciding on. Marketing site contract: no code is imported into `/public/` or `/api/` from the reference.

## What aidictation has that A-Anie deliberately does not

| aidictation component | A-Anie equivalent | Status | Codified in |
|---|---|---|---|
| `AIDictation.Windows` (.NET 8 / WPF) | not built | DELIBERATE CUT | D005 |
| `AIDictationAndroid` (Kotlin / Gradle) | not built | DELIBERATE CUT | D005 |
| `Whishpermate/` (Swift / iOS / macOS, Xcode) | A-Anie's desktop app (external repo) | external | — |
| Supabase backend (auth + Postgres + edge functions) | none — A-Anie is on-device | DELIBERATE CUT | D005 |
| Stripe webhook for paid tier | none — free during early access | DELIBERATE CUT | D005 |
| AppSumo webhook for partner tier | none | DELIBERATE CUT | D005 |
| `groq-large-v3-turbo` cloud transcription (free tier) | A-Anie uses whisper.cpp locally | DELIBERATE CUT | D005 |
| Free tier 2000-word lifetime cap | none — no metering | DELIBERATE CUT | D005 |
| `CLAUDE.md` (release + UI + Swift coding rules) | our CLAUDE.md is project-scoped, not a release runbook | different scope | — |
| `sign-and-notarize.sh` | not yet — A-Anie desktop is unsigned or self-signed | future | — |

## What aidictation does that A-Anie could borrow (reference patterns)

| Pattern | Where it lives in aidictation | What it gives A-Anie |
|---|---|---|
| **Audio-processing failure contract** (phases 0-5, bounded stage deadlines, persisted states) | `docs/audio-processing-failure-contract.md` (9.4KB) | A clean specification of the *state machine* for a single dictation attempt. Marketing site cannot use it directly (it is a desktop-app contract), but it is the right shape for any future "what did the recorder do when the network dropped" UI. |
| **Personal-vocab / replacements / voice-shortcuts** as first-class concepts | `Whishpermate/` (Manager classes per the CLAUDE.md) | Already true in A-Anie's marketing copy. Codified as F010 (text exists). The implementation lives in the desktop app. |
| **MIT-licensed native client source** | `Whishpermate/`, `AIDictation.Windows/`, `AIDictationAndroid/` | If A-Anie's desktop app ever goes open source, this is the licensing model. Today the desktop app is not in this repo. |

## What A-Anie has that aidictation does not

| A-Anie component | aidictation equivalent | Status |
|---|---|---|
| A 6-Indian-language scope (Hindi, English, Marwari, Rajasthani, Urdu, Punjabi) | aidictation supports more languages but not this set | A-Anie is more focused on India |
| A one-developer / no-company / no-team positioning | aidictation has a team (Writingmate) and an `appsumo-webhook` | A-Anie is honest about being solo |
| A static marketing site that demonstrates the wispr surface in a browser | aidictation has a `marketing/` dir and a `website/` dir | A-Anie's marketing site is the reconstruction; aidictation's is presumably similar but not in the open-source bundle |
| A wispr `/demo/` byte-identical mirror | aidictation does not clone wispr | A-Anie's research-artifact stance is unique to this project |

## The audio-processing-failure-contract (worth borrowing the shape)

aidictation's `docs/audio-processing-failure-contract.md` defines six phases per recording attempt:

0. **Capture and finalize** — allocate stable ID, write every frame, close container under deadline.
1. **Promote source** — validate, fsync, atomically promote finalized partial, commit record.
2. **Recognize speech** — bounded local job or bounded sequential cloud requests; checkpoint.
3. **Clean up text** — optional bounded pass; raw text is the result on timeout/error.
4. **Commit result** — persist terminal state before dismissing.
5. **Deliver text** — paste/insert/share; never go back to `processing` on delivery failure.

Eight invariants, six persisted states. This is a good shape for any future A-Anie "what happened to my dictation" UI on the marketing site. Today, neither the marketing site nor the desktop app implements this contract. **A-Anie's current marketing site** simply says "Backend not deployed" on the 501 — which is honest (D001) but does not yet mirror the aidictation's six-phase model.

**Decision deferred.** When the desktop app's recorder behaviour becomes part of this repo's contract (e.g. a future "Recovery" page on the marketing site), the aidictation contract is the right starting point. For now, this is recorded as a future-work pattern, not a current requirement.

## What the reference does NOT justify

The reference does NOT justify:

- Adding cloud transcription to A-Anie (D005, deliberate cut).
- Adding a usage-metering backend (D005).
- Adding team/enterprise features (D005).
- Adding a Windows or Android build (D005).
- Adding Stripe/AppSumo/paid tiers (D005).

The reference is informative — it shows the architecture the paper describes, with a real Supabase + Stripe + edge-function implementation. A-Anie's product shape is deliberately narrower (solo-built, on-device, free during early access). The cuts in `harness/docs/ARCHITECTURE.md` are still the right cuts.

## Reference integrity

- **Source:** https://github.com/writingmate/aidictation
- **License:** MIT (per `LICENSE` in the repo).
- **Local copy:** `harness/reference/aidictation/` (shallow clone, 73MB).
- **Imported into A-Anie code:** nothing. The reference is read-only; we look at it, we do not pull from it.

## Re-evaluation triggers

- If the user asks "should A-Anie add Windows or Android?" → reference the aidictation build; then ask whether A-Anie's product shape still justifies single-platform. D005 reopens only if the answer is yes.
- If the user asks "should A-Anie add cloud transcription?" → reference the aidictation Supabase `transcribe` function. Then ask whether the on-device claim is still load-bearing. D005 reopens only if the answer is no.
- If the user asks "what does a dictation recovery UX look like?" → reference aidictation's six-phase contract. Adopt the *shape*, not the implementation.
