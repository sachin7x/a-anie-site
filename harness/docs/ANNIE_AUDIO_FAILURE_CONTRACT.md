# ANNIE — Audio Processing Failure Contract

> Architectural vocabulary adopted from a reference implementation. Not an implementation plan for A-Anie.

## ANNIE scope (read this first)

This document adopts the **six-phase audio-processing-failure contract** as architectural vocabulary and a failure-model reference for A-Anie. It does **not** mean that A-Anie has implemented aidictation's cloud STT, cloud LLM refinement, Supabase auth, Stripe / AppSumo billing, or any cross-platform native feature.

What A-Anie currently implements:

- **The `/app` web surface (the in-browser dictation entry, `public/app.html`) implements phase 0 only** — browser-side capture and finalize of an audio blob using `getUserMedia` + `AnalyserNode` + `MediaRecorder`. No audio is sent to a transcription backend.
- **The `POST /api/transcribe` endpoint is an honest 501 stub.** It is not phase 1, 2, 3, 4, or 5. It exists so the `/app` IIFE has a real network response to surface honestly, and so the contract the desktop app *would* call is visible on the marketing site.
- **Phases 1–5 are not implemented by the web surface and are not currently in scope.** The marketing site is a static clone of the wispr surface; the desktop A-Anie app (not in this repo) is the actual product.

What A-Anie explicitly does **not** adopt from the reference:

- Cloud transcription providers (`writingmate.ai`, `groq/whisper-*`, Soniox, etc.)
- Cloud LLM post-processing (Groq, OpenAI, Ollama `chat/completions`)
- Supabase / auth / accounts / `aidictation://` deep-link callbacks
- Stripe or AppSumo billing
- Cross-platform native builds (iOS keyboard, Live Activity, Android asset-pack delivery, Windows installer)
- Sparkle / appcast auto-update machinery
- IDE smart-paste with `@file.ext` mention resolution
- History persistence infrastructure

These remain deliberate cuts per D005. This document does not weaken D005.

## What is adopted (the vocabulary)

A-Anie adopts the **shape** of the contract:

- The **six phases** (capture / promote / recognize / cleanup / commit / deliver) as a vocabulary for naming what is and is not currently built.
- The **eight invariants** as design constraints to be aware of when later work touches the audio pipeline.
- The **persisted state names** (`processing` / `retrying` / `success` / `failed` / `cancelled`) as canonical labels.
- The **request policy** (200 = 1 attempt, 4xx = 1 attempt, 408/429/5xx = bounded retry, 413 = split-and-retry) as a reference for what a future real transcription pipeline would have to honor.
- The **21 deterministic scenarios** as a checklist for future test expansion, not as a claim that A-Anie currently passes them.

## What is not a claim

This document does **not** claim:

- That the A-Anie web `/app` page currently implements any of the deterministic scenarios.
- That the marketing site's `/api/transcribe` handler runs any of the failure-recovery behavior.
- That A-Anie's desktop app (external to this repo) implements the contract.
- That any future A-Anie work is committed to filling in phases 1–5 in this repo.

The contract is documented here so a future agent — when asked about the audio pipeline, the failure model, or the request policy — can find the canonical reference, the ANNIE-specific scope boundary, and the deliberate cuts in one place.

## Provenance

- **Source contract (verbatim below):** `harness/reference/aidictation/docs/audio-processing-failure-contract.md` (HEAD `b30e846`, repository `writingmate/aidictation`, MIT-licensed; local read-only reference at `harness/reference/aidictation/`)
- **Audit that recommended adoption:** `harness/ANNIE_V2_AIDICTATION_WISPR_ARCHITECTURE_AUDIT.md` (P0 list, §10 / §11)
- **Settled decision:** `harness/state/decisions.md` D008 (six-phase contract adopted as vocabulary)
- **Smoke check:** `harness/scripts/smoke.sh` confirms this file's presence on every run

---

# Audio processing failure contract

This contract applies to macOS, iOS and its keyboard extension, Android, and Windows.

The remainder of this document is the reference contract, copied verbatim from `harness/reference/aidictation/docs/audio-processing-failure-contract.md`. The wording, structure, and content are unchanged. A-Anie does not claim authorship of this section; it is reference material for vocabulary and failure-model reasoning.

---

## Top-down attempt lifecycle

Every platform follows the same six phases. Later optional work is never allowed to undo an
earlier durable result.

| Phase | Durable state | What must happen before moving on | Failure result |
|---|---|---|---|
| 0. Capture and finalize | durable preparation/capture journal | Allocate the stable ID and managed partial source first, write every audio frame, monitor capture health, and close the container under a bounded stop/finalize deadline | Return to idle with a microphone or storage message. Never submit a truncated or unfinalized source as a normal recording |
| 1. Promote source | capture journal → `processing` | Validate, fsync, and atomically promote the already-managed finalized partial, then commit its stable recording record | Stop before recognition. Do not claim the recording is saved unless both the source and record are durable |
| 2. Recognize speech | `processing` or `retrying` | Run one bounded local job or bounded sequential cloud requests; checkpoint completed leaves | `failed`, with source and the last durable ordered checkpoint |
| 3. Clean up text | active state, with complete raw text already available | Run one separately bounded optional cleanup pass | Raw text becomes the result on timeout, HTTP error, invalid/empty/truncated output, or unavailable cleanup |
| 4. Commit result | active → `success`, `failed`, or `cancelled` | Persist the terminal state before dismissing the workflow | The UI still becomes idle and explains that History could not be updated; startup recovery uses retained managed audio |
| 5. Deliver text | already `success` | Paste, insert, share, or hand off the durable text | Delivery failure never returns the recording to `processing`; the text remains available to copy or retry delivery |

The recording indicator belongs to phase 0. The visible processing indicator belongs only to phases
1–4. Clipboard access, app activation, usage reporting, analytics, and other delivery-side work must
not hold it open.

## Invariants

1. Allocate the stable recording ID and managed partial source before capture. Persist and validate the finalized source before recognition.
2. Every active attempt has one owner, a deadline, cancellation, and a terminal persisted state.
   Capture, finalization, recognition, and cleanup use distinct bounded stage deadlines; reaching the
   capture limit must still leave enough bounded time to close and validate the container.
3. A relaunch converts abandoned active work to a recoverable failure; it never displays an endless processing state.
4. A retry updates the same recording ID. It does not create duplicate history entries.
5. Recognition is the required stage. Optional cleanup may improve successful text, but cleanup failure, timeout, or empty output returns the raw transcript.
6. Chunk uploads run sequentially. Completed text is checkpointed in order, and cleanup runs once after the complete merge.
7. Never delete the only recoverable audio copy. Never claim that a recording was saved until durable persistence succeeds.
8. Every callback carries its recording ID, attempt ID, and deletion generation. Stale callbacks have no effect.

## Persisted states

| State | Meaning | Allowed next states |
|---|---|---|
| `processing` | Source is durable and one attempt owns the recording | `success`, `failed`, `cancelled` |
| `retrying` | A retry owns the same durable recording | `success`, `failed`, `cancelled` |
| `success` | Final text is durable; raw audio remains available under retention policy | `retrying` |
| `failed` | Work ended; source and any completed partial text are durable | `retrying` |
| `cancelled` | The user or a replacement attempt stopped the work; source remains recoverable | `retrying` |

If a platform does not expose `cancelled` separately in its UI, it may persist it as `failed` with a
cancellation reason. It must still be terminal and retryable.

## Request policy

| Failure | Attempts | Recovery |
|---|---:|---|
| Complete `200` response | 1 | Accept only after the full body and strict response schema are available; `202` and `206` are not complete transcription results |
| Permanent `4xx` (`400`, `401`, `403`, `404`, `409`, `422`, and every other `4xx` except `408`, `413`, `429`) | 1 | Fail immediately; preserve source and partial text; show an actionable settings/request message |
| `408`, `429`, `500...599` | Up to 3 total | Retry with bounded backoff; honor `Retry-After` and cap the delay at 10 seconds |
| Transient connection loss, DNS/connect failure, request timeout | Up to 3 total | Same bounded retry policy |
| I/O timeout or disconnect while draining a successful response body | Up to 3 total | Treat it as a transient transport failure; retry the current request without replaying completed chunks |
| `413` | No replay of completed chunks | Split only the rejected audio leaf, continue sequentially, and stop at a bounded depth/minimum size |
| Cancellation | 1 | Cancel the request/export/decoder immediately; do not retry or allow a late result to mutate state |
| Invalid response or decode error | 1 | Fail; preserve source and completed partial text |
| Local engine timeout/failure | 1 per attempt | Cancel/reset the engine, persist failure, allow an explicit retry |
| Cleanup timeout/error/empty output | Cleanup is bounded separately | Keep the successful raw transcript; do not convert recognition success into failure |

## Local and persistence failures

| Failure | State and recovery |
|---|---|
| Capture write, recorder health, or container finalization fails/stalls | Stop or detach the recorder under a bounded deadline, return the UI to idle, and do not start recognition from a source known to be truncated or unfinalized |
| Source move or initial journal write fails | Do not start recognition. Return to idle with a storage message. Only say the recording was saved if the durable commit actually succeeded |
| Audio export, split, decode, or local model setup fails | Cancel/reset that operation, persist `failed`, retain the original source, and allow retry |
| A successful response body times out or disconnects before it is complete | Apply the bounded transient transport retry policy; never wait forever after headers |
| A fully received successful response has a malformed or undecodable body | Treat it as an invalid response with one attempt. Preserve the source and checkpoint |
| Dictated text happens to look like JSON | Preserve it literally for a text response. Only unwrap a JSON response when its media type and complete single-field schema identify a transcription envelope |
| A chunk returns empty text | Fail that leaf instead of silently omitting part of the recording. Preserve earlier ordered checkpoints |
| Complete single-file recognition contains no speech | Persist a terminal no-speech failure; never leave a spinner active |
| Checkpoint write fails | Stop the attempt. Do not process later leaves that could no longer be recovered in order |
| Final terminal write fails | End the in-memory processing state, retain the best source/text available, and show a truthful storage warning |
| Process or app dies while active | On the next launch, normalize abandoned active rows to recoverable `failed`; expire overlays, live activities, keyboard handoffs, and in-memory sessions |
| Delete or Clear races active work | A platform may block the action until active work stops. If deletion is accepted, it wins: late checkpoints must not recreate the row, and startup recovery must honor the deletion intent |
| Clipboard, accessibility, paste, or target-app delivery fails | Keep `success`; the transcript stays in History and processing remains closed |
| Settings change during an attempt | The running attempt keeps its captured provider, model, language, vocabulary, and cleanup configuration; the next attempt uses the new settings |

## Bulk and chunk behavior

- Split before upload when the known safe size is exceeded.
- A server may enforce a smaller unknown limit; any rejected leaf can be split again.
- Upload leaves one at a time so text order and resource use are deterministic.
- After each successful leaf, persist the ordered merged checkpoint.
- If a later leaf fails, the recording is `failed` with that checkpoint and the original source.
- Retrying starts a new attempt for the same recording. Old attempt callbacks are ignored.

## Relaunch recovery

At startup, normalize persisted `processing` and `retrying` entries to `failed` with a plain recovery
message. Keep their audio and checkpoint text. Platform-specific in-memory spinners, overlays, live
activities, and keyboard handoff sessions must also expire or restore to a terminal state.

## Required deterministic scenarios

Each platform must cover capture-write failure, stalled finalization, permanent `4xx`, retryable
`408`/`429`/`5xx`, a disconnected successful-response body, a fully received malformed response,
repeated timeout, cancellation, initial and nested `413`, stalled native chunk export, ordered
three-chunk checkpointing, cleanup fallback, process death during processing and retry, two
simultaneous retries competing for one recording ID, retry success without duplication, delete/clear
racing a late callback, cancellation racing the first captured buffer, maximum-length capture still
entering bounded finalization, storage failure, and concurrent jobs retaining their own provider
configuration.
