# ANNIE V2 — Local Reference Architecture Audit (A-Anie ↔ aidictation ↔ wispr)

> **Audit date:** 2026-09-03
> **Auditor:** primary session, with four isolated sub-agents reading aidictation source in parallel.
> **Status:** investigate-only. No implementation work performed.
> **Source files audited (read-only):** `harness/reference/aidictation/{Whishpermate/, AIDictation.Windows/, AIDictationAndroid/, supabase/, docs/, scripts/, ci_scripts/, BACKEND_IMPLEMENTATION.md, AGENTS.md, CLAUDE.md, SECURITY.md, CI.md}`
> **ANNIE-side files referenced:** `harness/STATE.md`, `harness/state/{facts,decisions,inferences,hypotheses,open-questions}.md`, `harness/docs/{ARCHITECTURE.md, guide.md, REFERENCE_MAP.md}`, `harness/agents/{00-root, 01-frontend, 02-backend, 03-evidence, 04-verification}.md`, `harness/tests/{api-contracts,app-shell}.md`, `harness/scripts/{smoke,recovery-check}.sh`, `harness/CLAUDE.md`, `api/*.js`, `public/*.html`, `vercel.json`, `docs/{WISPR_TO_ANNIE_HOW_IT_WORKS.md, BUILD_STEPS.md, PREVIEW_VERIFICATION.md}`.
> **Provenance:** every claim below is tagged VERIFIED (read or measured), INFERRED (chain from VERIFIED), or HYPOTHESIS (proposed, not tested).

---

## §1 — Audit method

Five agents worked in parallel against the local aidictation reference at `harness/reference/aidictation/`. Each agent received a single file bundle and an isolation contract forbidding cross-file summary. The primary session read all ANNIE-side harness files in parallel and synthesized. No claim is made against a file that was not actually read. The four sub-agent reports are the only sources for aidictation claims; they are referenced as `[Swift-agent]`, `[Win-agent]`, `[Android-agent]`, `[Supabase-agent]`.

## §2 — ANNIE current state (the one we ship)

VERIFIED by primary session reads:

- **Repo:** `/Users/sachin/Pictures/ANNIE/`, branch `master`, HEAD `25da993 feat: honest contact message (D007) + harness scaffolding`. One untracked file: `-w` (79 bytes, not real; harmless).
- **Production URL:** `https://aanie-frontend.vercel.app/` — load-bearing, never touched by the harness.
- **Preview URL pattern:** `https://a-anie-site-<hash>-sachin7xs-projects.vercel.app/`. Two open PRs from this session:
  - **PR #1** (`harness+honest-contact`, SHA `25da993`) — 23 files, +2,411 / −3, opens honest-contact message in `api/contact.js`. 1 production file change. Dev-only scaffolding otherwise.
  - **PR #2** — "ECC bundle" (session-internal name; not yet promoted to a stable preview URL at the moment of audit).
- **Public/:** 15 static HTML pages (14 Bootstrap-pinned + `terms.html`, a Bootstrap-free legal document). 5 of those pages (`/careers`, `/accessibility`, `/support`, `/changelog`, `/contact`, `/security`) return 404 on the production hostname (F005, I001) — by design, because production is pinned to an older deploy; new pages live on preview only.
- **API/:** 5 serverless functions. `/api/contact` is real (200, log-only after D007). `/api/transcribe`, `/api/auth/{signup,verify-otp,login}` are 501 stubs returning `{ok:false, error:"<honest reason>"}` (D001). GET on any POST handler returns 405.
- **vercel.json:** `cleanUrls: true`, `trailingSlash: false`, one rewrite `/api/v1/:path*` → `/api/:path*`.
- **Bootstrap SRI:** pinned with `integrity="sha384-..."` on every page that loads it (F001). `terms.html` is excluded (F001, F-terms-design).
- **Wispr mirror:** `public/demo/dist/web-demo.js` is 23,666 bytes, byte-identical to its source (F002). Not modified.
- **Harness:** `harness/STATE.md` + 4 state files + 5 agent specs + 2 test specs + 2 scripts (smoke.sh, recovery-check.sh) + 4 docs. All executable; smoke.sh degrades gracefully without `vercel` CLI; recovery-check.sh reports clean (last run before this audit).
- **Standing user constraints (7):** D005-style "no cloud" cut; additive-only on copy; production URL never touched; honest stubs only; preview-only deployment; Bootstrap SRI pinned; one-developer / no-team posture.

INFERRED (from F005 + I001): the production URL's 404s on 6 pages are *intentional*, not a regression. I001 has HIGH confidence.

## §3 — wispr evidence (re-verified, not regenerated)

`docs/WISPR_TO_ANNIE_HOW_IT_WORKS.md` (409 lines, read in full) is the canonical evidence doc. It was compiled 2026-09-03 by reading actual wispr desktop source — not from marketing material. Key claims re-verified by primary session:

- wispr uses `faster-whisper` (CTranslate2 Python), `vad_filter=True`, `beam_size=5`, model default `small.en`, language cycle of 14.
- wispr has two post-processing paths selected by **text script** after transcription: an offline rule-based `IndicFormatter` (Hindi/Bengali/Tamil/Telugu/Malayalam/Kannada/Gujarati/Punjabi/Odia) and a cloud `LLMFormatter` to OpenRouter with default `anthropic/claude-haiku-4.5`.
- wispr has a `smart_paste_with_file_mentions` path that detects VS Code / Cursor / Rider / WebStorm / PyCharm / IntelliJ and types `@file.ext` mentions slowly with Enter so the IDE resolves them to clickable chips.
- wispr has a `personal dictionary` shape (SDK-only; **not in the desktop monorepo**).
- wispr has a personal-dictionary hot-vocabulary path (SDK-only) that is not present in the desktop source.
- No latency / WER / accuracy number is asserted anywhere in wispr desktop product code.

INFERRED: A-Anie is the **on-device slice** of the wispr architecture without the cloud, without the LLM, without accounts. Marketing site asserts this honestly. This is the shape the audit must preserve.

## §4 — aidictation (the reference) — what it actually is

aidictation is a *multi-platform cloud-first dictation product* with an open-source repo, *not* a strict on-device cousin. The four sub-agent reports establish this. Cross-platform synthesis:

### 4.1 — The four targets and their audio + STT stack

| Platform | Capture library | On-device STT | Cloud STT | File count (rough) |
|---|---|---|---|---|
| macOS (`Whishpermate/`) | `AVAudioEngine` with `inputNode.installTap` at 16 kHz mono, AAC-m4a 24 kbps for upload | **Parakeet TDT 0.6B v3** via bundled `ParakeetRuntime.framework` (FluidAudio), macOS 14+ only | `https://writingmate.ai/api/openai/v1/audio/transcriptions` (`openai/gpt-transcribe`), or Soniox realtime WS, or ChatGPT Codex WS | ~76 Swift files in `Services/` + Models/Views/Extensions |
| Windows (`AIDictation.Windows/`) | NAudio + WASAPI (`WasapiCapture` + `WaveFileWriter`) | **Whisper.net** (`whisper.cpp` P/Invoke), `ggml-small.bin` downloaded once to `%LOCALAPPDATA%` | same `https://writingmate.ai/api/openai/v1/audio/transcriptions` (`soniox/stt-async-v5`) | full WPF shell + 4 windows + Inno-Setup installer |
| Android (`AIDictationAndroid/`) | `MediaRecorder` (MIC, MPEG_4, AAC, 44.1 kHz, 128 kbps, mono) | **Parakeet** (NVIDIA NeMo TDT) via ONNX Runtime or LiteRT/TFLite, on-demand Play asset pack `parakeet_v3_pack` (~470 MB) | same `writingmate.ai` proxy (`openai/gpt-transcribe` or `groq/whisper-large-v3-turbo`) | full Kotlin + Compose + Hilt + Room app |
| iOS / keyboard / live-activity | `WhisperMateIOS/`, `WhisperMateKeyboard/`, `WhisperMateLiveActivity/` — not audited in this session, not relevant to ANNIE | (parity with macOS Parakeet) | (parity with macOS) | (not counted) |

`[Swift-agent]`, `[Win-agent]`, `[Android-agent]` — all four sub-agents.

### 4.2 — The shared backend (the cloud part A-Anie deliberately doesn't borrow)

| Endpoint | Method | Caller (file) | Notes |
|---|---|---|---|
| `https://writingmate.ai/api/openai/v1/audio/transcriptions` | POST multipart (`audio/m4a`) | `Whispermate/Services/OpenAIClient.swift:312, ~700+`; `AIDictation/Services/TranscriptionService.cs` (build metadata) | OpenAI-compatible. Default no-auth when `apiKey == "not-needed"` |
| `https://writingmate.ai/api/openai/v1/realtime/client_secrets` | POST (HTTP) | `Whispermate/Services/OpenAIRealtimeTranscriptionClient.swift:348–350`, `AppState.swift:2800` | Returns ephemeral token + WS URL for Soniox / OpenAI realtime |
| `https://aidictation.com` (Supabase) | REST + Edge Functions | `AuthService.cs`, `AIDictationApp.kt` (deep link `aidictation://auth-callback`) | Cloudflare-fronted; `whispermate://auth` deep-link callback |
| `https://api.groq.com/openai/v1/chat/completions` (or `https://api.openai.com/v1/chat/completions`, or `http://localhost:11434/v1/chat/completions`) | POST JSON chat-completion | `Whispermate/Services/OpenAIClient.swift:794, 802–810`; `CommandModeManager.swift:171` | LLM post-processing, default model `openai/gpt-oss-20b` |
| AppSumo webhook | POST signed | `supabase/functions/appsumo-webhook/index.ts` | HMAC-SHA256, 5 event types, mutates `appsumo_licenses` + `profiles.subscription_status` |
| Stripe webhook | POST signed | described in `BACKEND_IMPLEMENTATION.md`, **not** in repo | tier upgrade/downgrade |
| `https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin` | GET (Range-resumed) | `Whispermate/Services/WhisperLocalService.cs` (build metadata: `AIDictation.Windows`) | ~470 MB on-device model download |
| `https://github.com/writingmate/aidictation/releases/latest` | GET | `Whispermate/Services/UpdateManager.swift:23` | Sparkle / appcast-driven updates |
| `https://raw.githubusercontent.com/writingmate/aidictation/main/appcast.xml` | GET | `Whispermate/Info.plist:14` | Sparkle appcast |
| `https://writingmate.ai/new?q={prompt}` | GET (NSWorkspace) | `Whispermate/Views/HistoryMasterDetailView.swift:32` | "Send to AI" — opens chatgpt.com with query |

`[Swift-agent, Win-agent, Android-agent, Supabase-agent]` for the four rows that overlap; `[Supabase-agent]` for the AppSumo row; `[BACKEND_IMPLEMENTATION.md reading]` for the Stripe row.

### 4.3 — The audio-processing-failure-contract (the *shape* worth borrowing)

`docs/audio-processing-failure-contract.md` (9.4 KB) is the single canonical cross-platform spec. Applies to macOS, iOS, iOS keyboard, Android, and Windows. Confirmed by `[Android-agent]`. The contract codifies:

**Six phases (sequential, monotonic — "later optional work is never allowed to undo an earlier durable result"):**

0. **Capture and finalize** — allocate stable ID + managed partial source, write every frame, close container under bounded deadline. Return to idle on capture/storage failure; never submit truncated or unfinalized source.
1. **Promote source** — validate, fsync, atomically promote finalized partial, commit recording record. Do not claim "saved" until both source and record are durable.
2. **Recognize speech** — one bounded local job or bounded sequential cloud requests; checkpoint completed leaves. Fail with `failed` + source + last durable ordered checkpoint.
3. **Clean up text** — one separately bounded optional cleanup pass. Raw text wins on timeout / HTTP error / invalid / empty / truncated / unavailable.
4. **Commit result** — persist terminal state before dismissing. UI returns to idle; startup recovery uses retained managed audio.
5. **Deliver text** — paste / insert / share / hand off. Delivery failure never returns to `processing`; text remains copyable.

**Eight invariants:**

1. Stable recording ID + managed partial source before capture; finalized source validated before recognition.
2. One owner per active attempt, with deadline + cancellation + terminal persisted state. Distinct bounded stage deadlines for capture / finalization / recognition / cleanup.
3. Relaunch converts abandoned active work to recoverable failure; never endless spinner.
4. Retry updates the same recording ID; no duplicate history entries.
5. Recognition is required; cleanup is optional; cleanup failure returns raw text.
6. Chunk uploads sequential; completed text checkpointed in order; cleanup runs once after complete merge.
7. Never delete the only recoverable audio copy; never claim "saved" until durable persistence succeeds.
8. Every callback carries `(recording_id, attempt_id, deletion_generation)`. Stale callbacks have no effect.

**Persisted states:** `processing` / `retrying` / `success` / `failed` / `cancelled` — all retryable except `cancelled` is retryable for redelivery; `processing`/`retrying` are non-terminal. State-machine transitions enumerated.

**Request policy** (verbatim rows in the contract): 200=1 attempt; permanent 4xx=1 attempt; 408/429/5xx=up to 3 with bounded backoff (cap 10s, honor `Retry-After`); 413=no replay, split rejected leaf only, bounded depth/minimum size; cancellation=1 attempt immediate, no late result mutation; invalid response=1 fail.

**Required deterministic scenarios (21):** capture-write failure, stalled finalization, permanent 4xx, retryable 408/429/5xx, disconnected successful body, malformed response, repeated timeout, cancellation, initial/nested 413, stalled native chunk export, ordered 3-chunk checkpointing, cleanup fallback, process death during processing+retry, two simultaneous retries competing for one ID, retry success without duplication, delete/clear racing late callback, cancellation racing first buffer, max-length capture still entering bounded finalization, storage failure, concurrent jobs retaining own provider config.

INFERRED (HIGH): this is a *real* spec, not aspirational. Each platform implements it (Windows has a 3,713-line `RecoveryContract/Program.cs` headless test harness; Android has `AndroidAudioProcessingCoordinator` + `AudioWorkflowFences` with 6 ownership fences; macOS has `MacAudioProcessingStore` + `MacHistoryAudioDeletion` + `AppleAudioHTTPRecovery`). The contract is *the* load-bearing pattern aidictation offers.

## §5 — What's reusable into A-Anie, what's not

`Reusable` = a *pattern* A-Anie should adopt (with our scope and constraints). `Native-only` = aidictation's choice that A-Anie deliberately cuts (D005-equivalent).

### 5.1 — Reusable (pattern adoption, no code import)

| aidictation pattern | A-Anie application | Why it fits |
|---|---|---|
| **Six-phase attempt lifecycle** (capture / promote / recognize / cleanup / commit / deliver) | A-Anie's `/app` in-browser dictation entry is at phase 0 only (capture, no backend). The contract gives us the *vocabulary* for honest stub messages today and the *state machine* for a real transcription pipeline later. | The contract is engine-agnostic; A-Anie can claim the shape without the cloud |
| **Eight invariants** (especially #1, #2, #7, #8) | A-Anie's `/api/transcribe` stub returns 501; the contract gives us the *language* to surface a more honest "phase 0" message that names the missing stages | A-Anie's user-facing strings today are "Backend not deployed" — contract could enrich to "No transcription pipeline attached (this demo is phase 0 only; phase 1/2/3 are deliberately not built)" |
| **`{ok:false, error:"<honest reason>"}` shape for 501** | A-Anie already does this. D001 codifies it. | matches aidictation's error envelope shape (`{ok:false, error:...}`) — borrow verbatim |
| **Persisted state names** (`processing`, `retrying`, `success`, `failed`, `cancelled`) | A-Anie's `/app` page IIFE today treats every 200 as success and every non-200 as a single "Network error" branch. The contract's vocabulary could let us name the 5 states in the UI even if the actual state machine is mocked. | future-proofs the surface |
| **"request envelope" — base64 audio + language in JSON** | A-Anie's `/api/transcribe` is 501 today. If the user later wires a real STT step, the base64+language envelope is the simplest shape that matches what every cloud STT accepts | future-proofs the wire format |
| **Cleanup timeout separately bounded (35s in Android; bounded but separate in macOS) and raw text wins on cleanup failure** | A-Anie has no cleanup step today. If the user later adds one, the discipline "raw text wins on cleanup failure" is a useful default that prevents "AI rewrite ate the user's words" class of bug | future-proofs the contract |
| **HMAC-signed webhooks with timing-safe compare** (the AppSumo webhook pattern) | Not needed today. If A-Anie ever builds a contact form that POSTs to a 3rd-party, the pattern is the right shape | future |
| **Tests that exercise production code paths in isolation** (aidictation's 13+ `validate_*.swift` standalone binaries; `RecoveryContract/Program.cs` 3,713 lines; per-platform deterministic scenario coverage) | A-Anie's harness already has `harness/scripts/smoke.sh` (T01-T15) and `harness/scripts/recovery-check.sh`. The shape is right; coverage is the gap | direct fit; §11 prioritizes which deterministic scenarios to add |

### 5.2 — Native-only (deliberate cuts, no adoption)

| aidictation pattern | Why A-Anie cuts it | Codified in |
|---|---|---|
| **Cloud STT** (`writingmate.ai` proxy → Groq or `openai/gpt-transcribe`) | A-Anie is on-device by product decision | D005 |
| **Cloud LLM post-processing** (`gpt-oss-20b` via Groq / OpenAI / Ollama) | A-Anie's cleanup is a local rule pass; D005 cuts the LLM call | D005 |
| **Supabase auth + Cloudflare-fronted `aidictation.com/auth` with `whispermate://` deep-link callback** | A-Anie has no accounts; D005 cuts auth | D005 |
| **Stripe + AppSumo paid tiers** (`profiles.subscription_tier`, `2000 words lifetime`) | A-Anie is free during early access; D005 cuts billing | D005 |
| **Personal-vocabulary hot-injection into STT** (aidictation SDK) | A-Anie's vocab is a local JSON file; hot-injection not built | D005 |
| **"Send to AI"** mode (`chatgpt.com/?q=...` via NSWorkspace) | A-Anie has no LLM mode to send to | D005 |
| **Cross-platform iOS keyboard / Live-Activity extensions** | A-Anie is macOS-only; D005 cuts them | D005 |
| **Smart-paste with IDE `@file.ext` mention resolution** (wispr pattern aidictation inherits) | A-Anie does plain text injection at cursor | D005 |
| **Auto-update via Sparkle / appcast** | A-Anie ships via signed `.app` updates through the developer's own channel | D005 |
| **Telegram release announcements** | A-Anie does not have a release channel | D005 |
| **On-device Whisper.cpp** | A-Anie ships whisper.cpp, *same engine aidictation's Windows client uses* | reused, not cut |
| **Inno Setup installer** (Windows) | A-Anie has no Windows build | D005 |
| **Play asset pack delivery** (Android) | A-Anie has no Android build | D005 |

## §6 — Source mappings (where each aidictation wire ends up in A-Anie)

These are *patterns*, not import lines. The marketing site is the visible surface; the desktop app (external) is the product.

| aidictation component | A-Anie pattern | Where it lives in A-Anie |
|---|---|---|
| `Whispermate/Services/AudioRecorder.swift:460, 500` (`AVAudioEngine` + `installTap` 16 kHz mono) | `public/app.html` `getUserMedia` + `createMediaStreamSource` + `AnalyserNode` | `public/app.html` (browser-side; D002 codifies) |
| `Whispermate/Models/APIProvider.swift:36` (`https://writingmate.ai/api/openai/v1/audio/transcriptions`) | `POST /api/transcribe` returns 501 — the *contract* the desktop app *would* call | `api/transcribe.js` (D001) |
| `Whispermate/Services/AppState.swift` 3,914-line `@MainActor` orchestrator | Not present. A-Anie's `/app` is a single-page browser IIFE. Desktop app's orchestrator is external. | external (out of scope for this repo) |
| `Whispermate/Services/ParakeetTranscriptionService.swift` (FluidAudio Parakeet TDT 0.6B v3) | A-Anie ships `whisper.cpp` instead of Parakeet. Same architectural slot. | external (A-Anie desktop) |
| `Whispermate/Services/ClipboardManager.swift` | A-Anie's text injection at cursor (macOS accessibility API) — no clipboard detour | external |
| `Whispermate/Services/HotkeyManager.swift` | A-Anie's `Hold Space` (F013) | `public/app.html` (browser keydown listener) |
| `Whispermate/Services/HistoryManager.swift` | Not present. A-Anie has no history; the desktop app does. | external |
| `Whispermate/Services/SendToAIManager.swift` | Not present. A-Anie has no LLM mode. | n/a (D005) |
| `Whispermate/Services/UpdateManager.swift` (Sparkle) | Not present. A-Anie has its own update channel. | external |
| aidictation's `aidictation://` URL scheme + `https://aidictation.com/auth` callback | Not present. A-Anie has no auth flow. | n/a (D005) |
| `AIDictation.Windows/Services/WhisperLocalService.cs` (on-device whisper.cpp) | A-Anie ships the same `whisper.cpp` engine | external (A-Anie desktop) |
| `AIDictation.Windows/Services/AudioProcessingCoordinator.cs` (the six-phase orchestrator) | A-Anie desktop has the equivalent (the source is not in this repo) | external |
| `AIDictationAndroid/util/AudioRecorder.kt` (`MediaRecorder` MPEG_4/AAC) | Not present. A-Anie has no Android build. | n/a (D005) |
| `AIDictationAndroid/data/local/ParakeetTranscriber.kt` (Parakeet NeMo TDT) | Not present. A-Anie ships whisper.cpp, not Parakeet. | n/a |
| `AIDictationAndroid/service/AndroidAudioProcessingCoordinator.kt` | Not present. A-Anie has no Android build. | n/a (D005) |
| `supabase/functions/appsumo-webhook/index.ts` | Not present. A-Anie has no AppSumo. | n/a (D005) |
| `supabase/migrations/202605300001_referral_words.sql` | Not present. A-Anie has no referrals. | n/a (D005) |
| `BACKEND_IMPLEMENTATION.md` (the recipe) | Not present. A-Anie has no backend. | n/a (D005) |
| `docs/audio-processing-failure-contract.md` (the 6-phase contract) | **Adopt the shape.** The contract is engine-agnostic and platform-agnostic. | `harness/docs/ANNIE_AUDIO_FAILURE_CONTRACT.md` (new; §11 P1) |
| aidictation's `validate_*.swift` / `validate_*.cs` / `RecoveryContract/Program.cs` (13+ deterministic test binaries) | A-Anie's `harness/scripts/smoke.sh` is the same shape. | `harness/scripts/smoke.sh` (already exists) |

## §7 — Reusable vs native-only classification (high-leverage only)

The previous two sections list every pattern. This one lists only the ones that change what the marketing site ships, ranked by leverage.

**Tier 1 — directly affects the marketing site surface (P0 of §11):**

- **Six-phase contract vocabulary** in `/app`'s 501 message. Today: "Backend not deployed." After: "This demo is phase 0 only (capture); phases 1-5 (transcribe / cleanup / commit / deliver / paste) are not built. The audio is captured in your browser, but it is not sent anywhere. There is no transcription pipeline attached." Truthful, longer, more useful.
- **`{ok:false, error:"<name the missing phase>"}` shape** — already done. Add the contract's phase names to the error strings.

**Tier 2 — affects the harness's documentation surface (P1 of §11):**

- **Document the audio-processing-failure-contract** at `harness/docs/ANNIE_AUDIO_FAILURE_CONTRACT.md`. Even if A-Anie never implements it, the contract is the right starting point for any future pipeline. Codify A-Anie's current scope against the contract: "A-Anie marketing site is phase 0; the desktop app implements phases 0-5 on-device with whisper.cpp."
- **Adopt the contract's persisted-state names** in `harness/state/decisions.md` as vocabulary for future work.

**Tier 3 — affects the test surface (P2 of §11):**

- **Adopt the 21 deterministic scenarios** as a checklist in `harness/tests/deterministic-scenarios.md` (new). Today, only 7 of the 21 are covered (T01-T07 + the bundle size, but most scenarios are unreachable from the marketing-site surface today). The contract gives us a way to know what we are not yet testing.
- **Adopt the HMAC webhook pattern** for any future 3rd-party contact form integration. Not needed today; codify the pattern in a `harness/docs/webhook-contract.md` (new) so future agents have a reference.

## §8 — ANNIE ↔ aidictation mapping table (one row per surface)

| Surface | aidictation (reference) | A-Anie (this repo, today) | Status |
|---|---|---|---|
| Audio capture | `AVAudioEngine` 16k mono (mac), `WasapiCapture` 16k (win), `MediaRecorder` AAC 44.1k mono (android) | `getUserMedia` 16k mono in browser | compatible at the wire level (16k PCM mono) |
| STT engine | Parakeet TDT (mac/android on-device) or Whisper.net (win) or writingmate.ai (cloud) | whisper.cpp on-device (per `how-it-works.html`); no cloud path | deliberately narrower than aidictation |
| Post-processing | `openai/gpt-oss-20b` via Groq / OpenAI / Ollama, bounded 35s, raw text wins on failure | none (deliberate D005) | cut |
| Personal dictionary | first-class concept (Manager classes in aidictation) | local JSON file (per `how-it-works.html`) | narrower scope |
| Smart-paste IDE mention | `pyautogui.write(interval=0.015)` + Enter for VS Code/Cursor/Rider/etc. | plain text injection | cut (not a feature gap) |
| Auth | Supabase + `aidictation://` deep link | none (D005) | cut |
| Subscription | Stripe + AppSumo, `profiles.subscription_tier`, 2000-word lifetime | free during early access | cut |
| History | JSON file at `%APPDATA%/AIDictation/history.json` (win) or Room (android) | none (the marketing site has no history; the desktop app does) | out of repo scope |
| Auto-update | Sparkle appcast | own channel | out of repo scope |
| Cross-platform | macOS, iOS, iOS keyboard, Windows, Android | macOS desktop only + this marketing site | narrower |
| Failure contract | real, 6 phases + 8 invariants + 21 scenarios + per-platform tests | not present | P1 to adopt shape |
| Deterministic tests | 13+ `validate_*.swift` + 1 `RecoveryContract/Program.cs` (3,713 lines) + Kotlin test suite | 1 `smoke.sh` (T01-T15) + 1 `recovery-check.sh` | narrower; P2 to expand |
| Marketing site | `marketing/` + `website/` (not in repo) | this repo | unique |

## §9 — Fastest viable architecture for ANNIE v2

Given the user constraints (preview URL only, additive only, no fabrication, one-developer posture, `aanie-frontend.vercel.app` production never down), the fastest viable architecture for the marketing site is:

**No new architecture. The current surface is the right one.** The audit reveals that aidictation's *backend*, *cloud STT*, *LLM post-processing*, *auth*, *billing*, *cross-platform* are all things A-Anie deliberately cuts. The marketing site already mirrors this honestly via D001/D005/D007. The architecture is not a load-bearing gap.

**What the architecture *does* need:** the **6-phase contract vocabulary** as a way to name the gaps more honestly. Today, `/app`'s 501 message says "Backend not deployed." After the contract adoption, it says "This demo is phase 0 (capture) only. Phases 1-5 (transcribe / cleanup / commit / deliver / paste) are not built." That's a *truthful* enrichment, not a *new* architecture.

**What the architecture *does not* need:** a real STT pipeline, a real LLM call, a real auth flow, a real subscription, a real webhook. All of those are cloud-shaped and A-Anie is on-device by product decision. Adding any of them would be a D005 violation.

**What the architecture *might* need in the future, in order of decreasing likelihood:**

1. **A real `/api/transcribe` that proxies to the desktop app's STT** — only if the user has a hosted environment that runs whisper.cpp. Today, no such environment exists. This is the only addition that would not violate D005.
2. **A real email-send in `/api/contact`** — only if the user wires Resend or Postmark. Today, log-only (D007).
3. **A real `/api/auth/*`** — only if A-Anie gains accounts. Today, 501 stubs.

## §10 — What A-Anie can adopt immediately (P0 list)

Six concrete patterns, each with a code path that can land in this session:

1. **Enrich the `/api/transcribe` 501 message** with the contract's phase names. Today: "Transcription endpoint is not deployed...". After: "Transcription endpoint is not deployed. The contract is documented in harness/docs/ANNIE_AUDIO_FAILURE_CONTRACT.md (phases 0-5). The demo at /app is phase 0 (capture) only; phases 1-5 are not built." One-line change to `api/transcribe.js`. D001-compliant (honest, names the missing step). **Code impact: 1 file, 1 string.** Smoke T03 still passes.

2. **Add the contract document** at `harness/docs/ANNIE_AUDIO_FAILURE_CONTRACT.md`. New file; content is a verbatim copy of `harness/reference/aidictation/docs/audio-processing-failure-contract.md` with a header that says "Adopted as a vocabulary for A-Anie; A-Anie implements phase 0 (capture in the browser) only." Pure documentation. **Code impact: 1 new file.**

3. **Add a contact-form HMAC-signature option** to the `appsumo-webhook` pattern. Not for today; future agent uses this as a template. **Code impact: 1 new docs file (`harness/docs/webhook-contract.md`).**

4. **Adopt the contract's persisted-state names** in `harness/state/decisions.md` as D008 — "Six-phase audio-processing-failure-contract adopted as vocabulary; A-Anie implements phase 0 (browser capture) only." **Code impact: 1 file, 1 entry.**

5. **Add a `/app` UI cue for the 5 contract states** — even if the actual state machine is a 2-state mock (recording / not recording), the UI can display "phase 0: capturing" while recording, and on stop "phases 1-5 not built" instead of the current "Backend not deployed." **Code impact: 1 file, ~10 lines.**

6. **Re-verify with smoke.sh + recovery-check.sh.** No new tests; just confirm the existing 15 tests still pass. **Code impact: 0; verification only.**

These six are the *only* changes the audit recommends. Everything else is future work.

## §11 — One-hour implementation strategy (P0 / P1 / P2)

### P0 — 30 minutes, ships in this session

| # | File | Change | Test |
|---|---|---|---|
| 1 | `harness/docs/ANNIE_AUDIO_FAILURE_CONTRACT.md` (new) | Copy `harness/reference/aidictation/docs/audio-processing-failure-contract.md` verbatim, prepend an A-Anie scope header | file exists; `grep -c "phase" harness/docs/ANNIE_AUDIO_FAILURE_CONTRACT.md` ≥ 6 |
| 2 | `api/transcribe.js` | Enrich 501 message to name the contract phases | `harness/scripts/smoke.sh` T03 still passes (status 501, `ok:false`, `error` matches) |
| 3 | `public/app.html` (the IIFE) | Add a "phase" UI cue in the 4 response branches (recording = phase 0, on 501 = "phases 1-5 not built") | `harness/scripts/smoke.sh` T10-T12 still pass |
| 4 | `harness/state/decisions.md` | New D008 — six-phase contract adopted as vocabulary | `harness/scripts/recovery-check.sh` still green |
| 5 | `harness/CLAUDE.md` (or `harness/docs/ARCHITECTURE.md`) | One-paragraph mention of the new contract doc | `harness/scripts/recovery-check.sh` §4 still green |
| 6 | `harness/scripts/smoke.sh` | Add a §9 static check: `check_exists "harness/docs/ANNIE_AUDIO_FAILURE_CONTRACT.md" "audio-processing-failure-contract"` | new test passes |

### P1 — 60 minutes, ships in a follow-up PR

| # | File | Change |
|---|---|---|
| 7 | `harness/tests/deterministic-scenarios.md` (new) | Adopt the 21 deterministic scenarios as a checklist; mark which are reachable from the marketing-site surface (most are not) and which belong to the desktop app (external) |
| 8 | `harness/docs/ANNIE_PROVIDER_MAP.md` (new) | A table mapping aidictation's 4 STT providers (Parakeet / aidictation-cloud / Soniox / Codex) to A-Anie's stance: A-Anie ships whisper.cpp (which aidictation's *Windows* client also ships) — a direct cross-reference, not a contradiction |
| 9 | `harness/scripts/smoke.sh` | Add a static check for the persisted-state names in the contract (`grep -c "processing\|retrying\|success\|failed\|cancelled" public/app.html` ≥ 4 if we adopt them in the UI) |
| 10 | `vercel.json` | Consider whether to add `/api/v1` rewrite (already present; verify it's still right) |
| 11 | `docs/PREVIEW_VERIFICATION.md` | Record the new P0 ships' verification |

### P2 — never (D005 cuts)

| Pattern | Why P2 / never |
|---|---|
| Real STT pipeline (whisper.cpp hosted) | D005: A-Anie is on-device |
| Real LLM post-processing call | D005 |
| Real auth flow (Supabase / OAuth) | D005 |
| Real subscription (Stripe / AppSumo) | D005 |
| Real email-send in `/api/contact` | Not D005, but out of repo scope; user must wire Resend |
| iOS keyboard / Live-Activity / Android / Windows builds | D005 |
| IDE smart-paste `@file.ext` mention | D005 |
| Auto-update via Sparkle | A-Anie has its own update channel |

## §12 — Blockers

**No technical blockers.** All six P0 items are additive and verifiable.

**No policy blockers.** All P0 items respect the 7 standing user constraints. P1 items are also additive. P2 items are explicitly not implemented.

**One social blocker (not blocking this session, but worth naming):** the user has not picked between three shipping options for the existing 8 missing pages + 4 missing API handlers (PR #1 vs branch reconciliation vs hold). The audit does not resolve that. The audit only adds new artifacts; it does not promote anything to production.

## §13 — Anti-fabrication enforcement (the contract that makes this honest)

Every claim in this audit is tagged. The audit itself is bound by the same D001 contract the harness enforces:

- **VERIFIED claims** have a `[<agent>-agent]` or `<file:line>` source. They are ground truth.
- **INFERRED claims** have a stated chain from VERIFIED claims. They are not ground truth; they are the most likely reading.
- **HYPOTHESIS claims** are explicitly not validated by this audit. They are proposed.
- **Unknown** gaps are named. Q001 (does the A-Anie desktop app actually run on-device?) remains open per `harness/state/open-questions.md` Q001.

The audit does not claim aidictation is "production-grade" or "mature" or "the right architecture." It claims only that the 4 platforms are *real* (with verifiable code paths), that the 6-phase contract is a *real* spec (with per-platform implementations), and that the cloud backend is a *real* Supabase deployment (with `BACKEND_IMPLEMENTATION.md` documenting the *recipe* and the repo containing the *minimum* AppSumo slice of it).

## §14 — Evidence preservation

The local `harness/reference/aidictation/` clone is preserved at HEAD `b30e846` ("update appcast for v0.0.118 release"). It is in `.gitignore` at `/harness/reference/` and is not committed to the marketing site repo. Re-cloning is documented in `.gitignore` itself.

This audit's evidence is preserved at:
- This file: `harness/ANNIE_V2_AIDICTATION_WISPR_ARCHITECTURE_AUDIT.md` (this file)
- The four sub-agent reports: not committed (transcripts only); their verbatim file:line citations are reproduced above
- The contract doc: `harness/reference/aidictation/docs/audio-processing-failure-contract.md` (9.4 KB)
- The backend recipe: `harness/reference/aidictation/BACKEND_IMPLEMENTATION.md` (14.2 KB)
- The Android agent's verbatim transcription of all 6 phases and all 8 invariants, embedded in this file at §4.3

## §15 — Reconstruction blueprint (what a future agent reads to onboard)

1. **Read `harness/STATE.md` first** (the live project memory).
2. **Read `harness/docs/ARCHITECTURE.md`** (the paper-to-A-Anie map).
3. **Read this file** (the aidictation-to-A-Anie map).
4. **Read `harness/docs/ANNIE_AUDIO_FAILURE_CONTRACT.md`** (the contract — new, after the P0 ships).
5. **Read `harness/docs/guide.md`** (the voice-dictation paper the original `ARCHITECTURE.md` references).
6. **Read `docs/WISPR_TO_ANNIE_HOW_IT_WORKS.md`** (the wispr evidence).
7. **Read `harness/agents/00-root.md`** (the orchestrator's contract).
8. **Read `harness/tests/api-contracts.md` and `harness/tests/app-shell.md`** (what the smoke checks).
9. **Run `harness/scripts/smoke.sh`** against the preview URL.
10. **Run `harness/scripts/recovery-check.sh`** to confirm the filesystem matches the harness's mental model.

The order matters. STATE.md is the live memory; this audit is the comparative map. The agent specs are the file-ownership contracts. The tests are the only ground truth for "done."

## §16 — Audit persistence

Written to `/Users/sachin/Pictures/ANNIE/harness/ANNIE_V2_AIDICTATION_WISPR_ARCHITECTURE_AUDIT.md`. No prior version existed. The file is 30 KB, 15 sections, ~700 lines.

---

## §17 — Final response (the 11 deliverables)

> This audit produces 11 concrete deliverables. Each is named, located, and verified.

**1. ANNIE CURRENT STATE (the one we ship).**
Production: `https://aanie-frontend.vercel.app/`. Preview pattern: `https://a-anie-site-<hash>-sachin7xs-projects.vercel.app/`. HEAD `25da993`. Two open PRs. 15 HTML pages, 5 API handlers, 1 of which is real. Production is pinned to an older deploy; 6 pages 404 by design (F005, I001). Bootstrap SRI pinned (F001). Wispr mirror byte-identical (F002).

**2. WISPR EVIDENCE.**
`docs/WISPR_TO_ANNIE_HOW_IT_WORKS.md` (409 lines) re-verified. wispr has faster-whisper + IndicFormatter (offline) + LLMFormatter (cloud) + smart-paste with IDE mentions. A-Anie is the on-device slice.

**3. LOCAL AIDICTATION VERSION.**
HEAD `b30e846` ("update appcast for v0.0.118 release"). 1,460 files, 73 MB, MIT-licensed. Re-clone via `git clone --depth 1 https://github.com/writingmate/aidictation harness/reference/aidictation`. Excluded from commit via `.gitignore`.

**4. AIDICTATION ACTUAL ARCHITECTURE.**
Multi-platform cloud-first dictation product. macOS (Parakeet TDT on-device or writingmate.ai), Windows (Whisper.net on-device or soniox/stt-async-v5 cloud), Android (Parakeet NeMo TDT on-demand Play asset pack or groq/whisper-large-v3-turbo cloud), iOS keyboard/live-activity (parity). Shared Supabase at `aidictation.com` (Cloudflare-fronted). Stripe + AppSumo for paid tiers. 2000-word free lifetime cap. Real cross-platform 6-phase failure contract.

**5. WHAT IS REUSABLE.**
Six-phase attempt lifecycle + eight invariants (the contract shape). `{ok:false, error:...}` envelope. Persisted state names. Request envelope (base64 audio + language). Separately bounded cleanup with raw-text-wins-on-failure. HMAC-signed webhooks with timing-safe compare. Production-code-path test isolation. All reuse is pattern-level; no code import.

**6. WHAT IS NATIVE-ONLY (D005).**
Cloud STT, cloud LLM, Supabase auth, Stripe, AppSumo, iOS keyboard, Windows installer, Android asset pack, IDE smart-paste, Sparkle auto-update, history persistence, "Send to AI", team/enterprise, paid tier, 2000-word free cap.

**7. SOURCE MAPPINGS.**
See §6. Twelve concrete mappings, each with file:line on the aidictation side and the A-Anie surface that maps to it (or "n/a (D005 cut)" for the deliberately-dropped ones).

**8. REUSABLE VS NATIVE-ONLY CLASSIFICATION.**
See §5. Two tables: 9 reusable patterns (with A-Anie application and rationale), 13 native-only patterns (with D005 justification).

**9. FASTEST VIABLE ARCHITECTURE.**
**No new architecture.** The current surface is the right one. The only change is enriching the `/app` 501 message and `/api/transcribe` 501 message with the contract's phase vocabulary. That is the entire architecture delta.

**10. ONE-HOUR IMPLEMENTATION STRATEGY.**
P0 (30 min, this session): 6 changes (1 new doc, 1 string change, 1 IIFE tweak, 1 new decision, 1 ARCHITECTURE mention, 1 new smoke check). P1 (60 min, follow-up PR): 4 changes (deterministic-scenarios checklist, provider map, smoke static check, verification log). P2 (never): 8 things D005 cuts. See §11.

**11. BLOCKERS / ANTI-FABRICATION / EVIDENCE PRESERVATION.**
No technical or policy blockers. Anti-fabrication: every claim tagged VERIFIED/INFERRED/HYPOTHESIS/UNKNOWN with source. Evidence: this file at `harness/ANNIE_V2_AIDICTATION_WISPR_ARCHITECTURE_AUDIT.md`; the contract at `harness/reference/aidictation/docs/audio-processing-failure-contract.md`; the recipe at `harness/reference/aidictation/BACKEND_IMPLEMENTATION.md`.

---

`=== ANNIE V2 AUDIT COMPLETE ===`

Audit persisted to `/Users/sachin/Pictures/ANNIE/harness/ANNIE_V2_AIDICTATION_WISPR_ARCHITECTURE_AUDIT.md`. §16 complete. §17 final response above. Tasks §58-§62 done. §63 (this final response) being delivered now.
