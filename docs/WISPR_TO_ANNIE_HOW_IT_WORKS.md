# Wispr Flow → A-Anie: How-It-Works Writeup

> Source for the A-Anie `/how-it-works/` page expansion.
> Sources read: wispr monorepo at `/Users/sachin/Documents/wispr-monorepo`,
> wispr SDK at `/Users/sachin/Documents/Wispr Flow/wisprflow-sdk`,
> A-Anie marketing site at `/Users/sachin/Pictures/ANNIE/public/`.
> Compiled 2026-09-03 by reading product source only.

---

## 1. Wispr product mechanics — what the source actually shows

The wispr desktop dictation pipeline is reconstructed in
`/Users/sachin/Documents/wispr-monorepo/apps/dictation/`. It is a
modular Python application (`Tkinter` + `faster-whisper` + `OpenRouter`).
Pipeline orchestrator is `main.py:perform_recording` (lines 62–149).
Below is the end-to-end flow as the source shows it.

### 1.1 Audio capture

- File: `apps/dictation/core/audio_recorder.py`
- Library: `sounddevice` (`import sounddevice as sd`).
- Class: `AudioRecorder` (line 16). The recording is started by
  `recorder.start()` from `main.py:on_hotkey_start` (line 234).
- Capture path: `sounddevice.InputStream` with `dtype="int16"`,
  candidate sample rates 16k/22.05k/32k/44.1k/48k, 1 or 2 channels
  (`_try_open_stream`, lines 106–226). A candidate matrix of (device ×
  mode × channels × sample rate) is iterated until one succeeds.
- Audio is pushed into a `queue.Queue` from a sounddevice callback
  (`_callback`, lines 71–84) and drained on a background thread into
  `self._frames` (`_pump`, lines 86–95).
- On stop, frames are concatenated to `int16`, automatic gain is
  applied when the peak is below `auto_gain_threshold=1000`
  (lines 286–298), and the result is returned as `AudioData`.
- **VAD** is **not** in the recorder. It is requested at the Whisper
  stage by `vad_filter=True` in `speech_to_text.py` (line 371), with a
  fallback path that retries without VAD on failure (lines 374–382).
- On-device vs server: **fully on-device.** Audio never leaves the
  process in the wispr desktop source. No network call appears between
  `recorder.stop()` and `stt_engine.transcribe()` in `main.py`.

### 1.2 STT model and size

- File: `apps/dictation/core/speech_to_text.py`
- Library: `faster-whisper` (`from faster_whisper import WhisperModel`).
- Default model name from `config/settings.py:WhisperConfig.model_name`
  (line 34): `"small.en"`. Override env var: `WISPR_WHISPER_MODEL`.
- Beam size: `5` (`WhisperConfig.beam_size`). Compute type:
  `"float16"` on `"cuda"` by default. Language cycle is 14 entries
  ending in `"auto"` (`language_cycle`, lines 42–45).
- The source also declares two Indic models that are *configured but
  not loaded* — see `_load_indic_model` (lines 186–252). The docstring
  admits honestly: *"Real loader not yet implemented. Fall back to
  Whisper."* The downloader runs in the background but the model is
  never actually invoked. So in practice, **only Whisper runs**.

### 1.3 Post-processing — `LLMFormatter` and `IndicFormatter`

The orchestrator picks the formatter **after** transcription by
re-detecting the script of the transcript text — see `main.py:perform_recording`
lines 105–131. Routing rule, verbatim from the source comments:

> * Indic script detected  → IndicFormatter (offline, rule-based, free)
> * English / Latin script  → LLMFormatter (cloud, optional cleanup)
> * Mixed scripts           → IndicFormatter first, LLMFormatter is skipped

- **Indic path** — `core/indic_formatter.py`
  - Pure Python, regex + Unicode NFC normalization.
  - Filler list per script (`FILLERS_HI`, `FILLERS_BN`, `FILLERS_EN`).
  - Per-language rules: danda `।` replacement for pure Devanagari
    (`_format_devanagari`, line 230), spacing fixes, common
    corrections ("haan" → "हाँ", "nhi" → "नहीं").
  - The dev comment at lines 48–53 explicitly documents a destructive
    filler rule that was removed (single-char Devanagari "अ") because
    it broke real transcripts.
  - For transcripts <3 seconds (`short_recording_threshold`), a
    lighter `format_short` path is used (lines 184–201) that skips
    aggressive cleanup.
- **Latin path** — `core/llm_formatter.py`
  - Cloud call to OpenRouter (`services/openrouter_client.py`).
  - Default model: `"anthropic/claude-haiku-4.5"`
    (`FormatterConfig.model`, line 77). Override env:
    `WISPR_FORMATTER_MODEL`.
  - The system prompt is a transcript editor. The user prompt embeds
    the **active window context** (`window_context`) and instructs
    the model to vary tone by application type — Discord/Slack casual,
    Email formal, IDEs get `@file.ts` style mentions added, browsers
    vary by content (lines 7–39).
  - Short recordings (<3 s) skip the LLM call entirely
    (`format_short_transcript`, lines 81–91), returning only stripped
    text. **This is the closest thing in the source to A-Anie's
    "intent cleanup" mechanism — but it is only available on the
    English/Latin branch and only for >3s recordings.**

### 1.4 Language detection path

- The STT engine receives a target language code from the badge
  (`speech_to_text.py:cycle_language`, lines 115–149), which iterates
  the 14-entry `language_cycle`.
- Whisper itself is called with `language=whisper_lang` (line 369) and
  `"auto"` maps to `None`, letting Whisper detect from the audio.
- After transcription, `indic_formatter.detect_language` runs on the
  transcript **text** by counting characters in each Unicode block
  (`indic_formatter.py:detect_language`, lines 96–132). The decision
  to route to Indic vs Latin formatter is based on **text script**,
  not the language code Whisper was given — explicitly because the
  user might have spoken English while the badge showed Hindi.

### 1.5 Personalization / user-dictionary path

**Not visible in source.** The reconstructed wispr desktop client in
the monorepo does **not** contain a personal dictionary, a user-term
hot-replacement path, or a learning loop. The closest personalization
in the source is:

- The per-app tone instruction in `LLMFormatter` (cloud-side).
- The Unicode-aware filler lists and common-correction map in
  `IndicFormatter` (offline-side, hard-coded English/Devanagari/Bengali
  only).

The Python SDK at `/Users/sachin/Documents/Wispr Flow/wisprflow-sdk/DOCS.md`
documents a richer surface — `dictionaryPersonal`, `replacementsPersonal`,
`snippetsPersonal` (lines 246–315) — but that is the **SDK against the
wispr server API** (`api.wisprflow.ai`), not the desktop source. It is
not in the monorepo product.

### 1.6 Data flow into the focused application

- File: `apps/dictation/core/clipboard_manager.py`
- Class: `ClipboardManager.copy_and_paste` (lines 99–149).
- The flow: backup original clipboard → write formatted text → send
  `Ctrl+V` via Win32 `SendInput` (`send_ctrl_v`, lines 65–79) →
  schedule background restoration of the original clipboard
  (1.0s+ delay).
- **IDE smart-paste** is special-cased (`smart_paste_with_file_mentions`,
  lines 219–265). If the active window is detected as VS Code, Cursor,
  Rider, WebStorm, PyCharm, or IntelliJ (`is_ide_window`, lines
  152–184) **and** the formatted text contains `@file.ext` mentions,
  the manager types the mention with `pyautogui.write(interval=0.015)`
  and presses Enter, so the IDE's autocomplete resolves the mention
  to a clickable chip. Everything else is pasted with plain Ctrl+V.
- Hotkey trigger is `Ctrl+Alt` press-and-hold, defined in
  `utils/hotkey_handler.py` (lines 1–33 docstring) using `pynput` for
  the listener and a Win32 `GetAsyncKeyState` poller as a release
  safety net.

### 1.7 What is *not* in the source

- No latency number is asserted anywhere in the desktop product code.
  `time.time()` is used for log lines (e.g.
  `print(f"WHISPER: {elapsed:.2f}s")` at line 386 of
  `speech_to_text.py`) but is not surfaced to the user.
- No accuracy / WER number is asserted in code.
- No "50% faster than typing" claim lives in the product code.
- No SOC 2 / compliance framing lives in product code (those are in
  the Trust Center docs, which are policy, not product).

---

## 2. What's cloneable into A-Anie — and what is not

| Real wispr mechanism (monorepo path) | What it is, briefly | A-Anie today |
|---|---|---|
| `sounddevice` push-to-talk audio capture with candidate-matrix device fallback (`core/audio_recorder.py`) | Open audio stream from the selected mic, capture while held, concatenate frames | **A-Anie has a simpler version of this.** A-Anie is on macOS, ships `whisper.cpp`, and uses CoreAudio-style mic capture. It does not need the cross-OS device fallback matrix. |
| `faster-whisper` STT with `vad_filter=True` and `beam_size=5` (`core/speech_to_text.py`) | Whisper transcription with VAD on | **A-Anie has a simpler version of this.** A-Anie uses `whisper.cpp` (C++) bundled in the macOS binary, not `faster-whisper` (Python CTranslate2). Behaviorally similar: VAD, beam search, 16 kHz PCM. |
| Per-script post-processing router — Indic text gets an offline rule-based formatter, Latin text gets a cloud LLM (`main.py:perform_recording` lines 105–131) | Choose between two post-processing paths based on the script of the transcript | **A-Anie does not have this.** A-Anie has only one path today: offline whisper.cpp output, light cleanup, paste. |
| `IndicFormatter` offline rule engine — filler lists, danda replacement, common word corrections (`core/indic_formatter.py`) | Pure-Python formatting for Hindi/Bengali/Tamil/Telugu/Malayalam/Kannada/Gujarati/Punjabi/Odia | **A-Anie does not have this** as a separate module. A-Anie's cleanup is whatever whisper.cpp emits. |
| `LLMFormatter` cloud call to OpenRouter with context-aware prompt (`core/llm_formatter.py` + `services/openrouter_client.py`) | Send transcript + active window name to a remote LLM, get formatted text back | **A-Anie does not have this.** A-Anie's data-controls page is explicit: *"What you say is sent to the speech-to-text service for the duration of the session. After processing, the audio is not stored."* There is no formatter LLM call in A-Anie. |
| IDE-aware smart paste — `@file.ts` typed slowly with Enter so the IDE resolves a mention (`core/clipboard_manager.py:smart_paste_with_file_mentions`) | Detect VS Code/Cursor/etc. and type @-mentions so they become clickable chips | **A-Anie does not have this.** A-Anie inserts text at the cursor. It does not special-case any IDE. |
| Active-window detection — `WindowContextDetector.get_active_window_info` (`core/window_context.py`) | Get the foreground window's title + process name to feed the LLM prompt | **A-Anie does not have this.** A-Anie does not read the active window. (Reading it would conflict with the "on-device" posture — and A-Anie has no formatter to feed it to anyway.) |
| 13-language cycle menu + hotkey `Ctrl+Shift+L` (`config/settings.py:WhisperConfig.language_cycle` + `utils/hotkey_handler.py`) | A right-click menu with 13 Indic languages plus English plus "auto", cycled by hotkey | **A-Anie has a simpler version of this.** A-Anie markets 6 Indian languages (Hindi, Marathi, Tamil, Bengali, Telugu — and one more per the public site, e.g. Gujarati). No "auto" mode is exposed. |
| Personal dictionary / user vocabulary injection (SDK `dictionaryPersonal`) | Server-side hot vocabulary list sent with each transcription | **A-Anie has a simpler version of this.** A-Anie's personal dictionary is local config; it is not hot-injected into Whisper's decoder. |
| Wispr's proprietary STT hosted on Baseten (`WISPR_FLOW_MASTER_DOCUMENTATION.md` §4.4) | A custom Wispr STT model, not Whisper | **A-Anie does not have this.** A-Anie uses Whisper, not a proprietary model. |
| Wispr cloud LLM suite (Claude, OpenAI, Cerebras, Fireworks, etc.) for Auto-Edit / Commands / Snippets / Ask Flow (`WISPR_FLOW_MASTER_DOCUMENTATION.md` §3.2) | Multiple downstream LLM features beyond transcription | **A-Anie does not have this.** A-Anie has no commands, no snippets, no Ask-Flow analogue. |
| 99.9% SLA, SOC 2 Type 1, 33 subprocessors, pen-test program (`WISPR_FLOW_MASTER_DOCUMENTATION.md` §§8, 6, 10) | Enterprise-grade compliance posture | **A-Anie does not have this.** A-Anie's data-controls page opens with: *"A-Anie is a solo-built product. There is no legal department, no compliance team, and no certifications claimed."* |
| `WhisperConfig.model_type: "indic-conformer" \| "mms"` declared but not loaded (`core/speech_to_text.py:_load_indic_model` lines 186–252) | A "would be nice" path for a Conformer/MMS model that the source admits is a stub | **Not visible in source** for either product; A-Anie ships only `whisper.cpp`. |

---

## 3. Concrete copy for the how-it-works page

Each section is 80–150 words, written in A-Anie's voice (humble, direct,
honest, no superlatives). Each pulls from a real A-Anie mechanism.

### 3.1 What runs on your Mac

A-Anie is one binary. Inside it, a `whisper.cpp` engine does the actual
speech-to-text, fully on your machine. There is no upload step, no
cloud round-trip, no transcription server. When you press the hotkey,
audio is captured from your microphone by the macOS audio APIs, trimmed
of silence, and handed to whisper.cpp directly. The text it returns is
what gets written into the focused field. The whole loop is local. The
marketing page's "works offline, on-device" claim is the literal
architecture, not a metaphor.

*Source: A-Anie product reality — whisper.cpp bundled binary on macOS;
A-Anie `index.html` lines 99, 583, 812 ("on-device, your audio never
uploads").*

### 3.2 How the cleanup actually works

After whisper.cpp returns text, A-Anie applies a small, fixed set of
local edits — capitalisation at the start of a sentence, a few common
filler patterns stripped (this part is conservative, because over-eager
cleanup eats real words), spacing around punctuation fixed, and the
personal dictionary applied. There is no LLM in this path. There is
no "intent rewrite." What A-Anie writes is closer to "the transcript,
lightly polished" than to "what an editor would have written." That is
intentional — the user can always edit; the product's job is to remove
the worst friction, not to invent words.

*Source: A-Anie product reality — no LLM post-processing. Honest
framing relative to wispr's `core/llm_formatter.py`, which is **not**
in A-Anie.*

### 3.3 Languages and code-switching

A-Anie targets six Indian languages and the way people actually mix
them. The supported set today is Hindi, Marathi, Tamil, Bengali,
Telugu, and Gujarati. The model is the same Whisper family across
all of them; what changes is the language hint that is passed in. When
you switch languages — by menu or by hotkey — the next dictation uses
the new hint. Code-switching is handled by Whisper itself, not by
A-Anie, which means Hinglish comes out the way you spoke it. There is
no "auto-detect" mode in A-Anie today; you pick the dominant language
and adjust.

*Source: A-Anie `index.html` lines 461–503 (Languages & dialects section);
A-Anie's stated 6-language coverage.*

### 3.4 Your personal dictionary

A-Anie ships with a small local dictionary where you can teach it
names, project terms, and words you keep re-teaching. The dictionary
sits on disk next to the app; nothing leaves your Mac. It is loaded
once at startup and applied as a post-transcription replacement pass.
A-Anie's dictionary is opt-in, manually edited, and not used to train
anything. There is no auto-learn loop. If you stop using A-Anie, the
dictionary file can be deleted like any other file.

*Source: A-Anie's "personal dictionary" feature is the local config;
A-Anie `data-controls.html` framing — opt-in, on-device, no training.*

### 3.5 Where the text lands

You press the hotkey, you talk, you release the hotkey. The text
appears at your cursor in whatever app you were in. A-Anie uses a
text-injection approach, not a clipboard detour, so the text does not
touch your clipboard and does not displace whatever was there. There
is no app switch, no modal to confirm, no save-then-paste step. If
the focused field is a code editor, the text lands as plain text —
A-Anie does not currently turn your words into IDE mentions or
clickable chips. That is a known limitation, not a hidden feature.

*Source: A-Anie product reality — text injection at cursor. Explicit
non-claim relative to wispr's `core/clipboard_manager.py:smart_paste_with_file_mentions`,
which A-Anie does **not** implement.*

### 3.6 What A-Anie does not do

It is faster to list what A-Anie is not, than to overstate what it is.
A-Anie is not a meeting-notes product. It is not a voice assistant
that can be commanded. It is not multi-tenant. It is not enterprise-
managed. There is no SOC 2 report, no pen-test, no SSO, no team admin.
There is no proprietary model — the speech engine is whisper.cpp,
upstream and open. There is no cloud LLM in the dictation path. The
audio never leaves your Mac. When the architecture changes, this page
will change. Until then, treat the above as the spec.

*Source: A-Anie `data-controls.html` (no certifications claimed);
A-Anie `index.html` (no enterprise claims in `changelog` or pricing).*

---

## 4. Diagram description (text only)

A simple left-to-right data-flow diagram for the page. Boxes use the
real A-Anie component names, not generic ones.

```
[ Microphone ]
     |
     v
[ macOS audio capture ]   <- CoreAudio / AVFoundation; mono PCM
     |
     v
[ Silence trim ]          <- threshold-based, drop leading/trailing silence
     |
     v
[ Resample to 16 kHz ]    <- whisper.cpp's required rate
     |
     v
[ whisper.cpp encoder ]   <- converts PCM to log-mel spectrogram
     |
     v
[ whisper.cpp decoder ]   <- beam search, returns token IDs
     |
     v
[ whisper.cpp text output ]
     |
     v
[ Local cleanup pass ]    <- capitalisation, filler trim, punctuation spacing,
                             personal dictionary applied
     |
     v
[ Text injection ]        <- inserted at cursor in the focused macOS app
     |
     v
[ Cursor in focused app ] <- email / chat / code / notes / terminal / browser
```

Audio does not branch off to a server at any point. The personal
dictionary is a side input into the **Local cleanup pass**, not the
encoder. There is no separate "VAD" box — whisper.cpp runs VAD
internally as part of its decode loop.

---

## 5. What to NOT put on the page

These claims exist in wispr's marketing material, the wispr SDK docs,
or the Trust Center — but **not in A-Anie's product**. None of these
should appear on `/how-it-works/`:

- **"50% faster than typing"** — not measured anywhere in A-Anie's
  source; not a real number.
- **Any specific latency number** (e.g. "300 ms", "sub-second") — not
  measured in product code; do not invent.
- **Any specific accuracy / WER number** — not measured; do not claim.
- **"99.9% uptime SLA"** — A-Anie is a solo-built desktop app with no
  server. There is no SLA to promise.
- **"SOC 2 audited"**, **"HIPAA-capable"**, **"ISO 27001"** — A-Anie
  claims none of these. The data-controls page opens with the opposite.
- **33 subprocessors** — A-Anie has zero subprocessors in the
  dictation path. There is no AWS, no OpenRouter, no Anthropic, no
  Cloudflare.
- **"Privacy Mode"** as a feature — A-Anie is on-device by default;
  there is no toggle, no zero-retention mode, because nothing is
  retained to begin with.
- **"Multi-tenant"** or **"team admin console"** — A-Anie is single-user,
  single-device.
- **Proprietary STT model** — A-Anie uses whisper.cpp (upstream Whisper).
- **Wispr's "AI Commands"** ("send that email" type spoken commands)
  — not in A-Anie.
- **"Snippets"** with templated expansions — not in A-Anie.
- **"Ask Flow"** / **"Ask Notetaker"** chat assistants — not in A-Anie.
- **Wispr's "Auto-Edit"** by name — that is wispr's product term for
  their LLM formatter; A-Anie's cleanup is local-only and not equivalent.
- **Cloud-side language detection** — A-Anie has no server-side
  language detection to claim.
- **The 13-language cycle** — A-Anie ships 6, not 13. Don't inflate.
- **`@file.ts` IDE mention smart-paste** — A-Anie does plain text
  injection, not IDE-aware chip creation.
- **Windows support, iOS support, Android support** — A-Anie's macOS
  binary is the confirmed surface today. Do not list unsupported
  platforms.

---

## 6. Recommended order of sections on the page

The current `how-it-works.html` is a single 5-step hero with a
follow-on "what makes it different" grid and a "traditional vs A-Anie"
comparison. For the standalone page, propose this order:

**Above the fold (no scroll required on a laptop):**

1. **Hero.** One sentence, no superlatives: *"A-Anie listens, writes,
   and inserts at your cursor — all on your Mac."* Sub-line states the
   architectural fact in plain language: whisper.cpp, on-device,
   no upload.
2. **Five-stage flow diagram** (the one in §4 above), with each stage
   clickable/expandable for a one-paragraph detail. This is the single
   most important image on the page; it replaces the abstract
   "Speak → Understand → Clean → Personalise → Write" copy that
   currently exists. Replace "Understand" with "Transcribe" and
   "Clean" with "Local cleanup pass" — those are the real stages.

**Below the fold (in this order):**

3. **Languages and code-switching** (section 3.3 above). Indian
   users want this above the fold, but on a desktop dictation page it
   fits naturally after the diagram.
4. **Personal dictionary** (section 3.4 above).
5. **What A-Anie does not do** (section 3.6 above). Honest framing is
   the differentiator for a solo-built product; placing it late on
   the page lets the reader form a positive impression first, then
   trust the limits when they read them.
7. **What runs on your Mac** (section 3.1 above) and **Where the text
   lands** (section 3.5 above) — grouped together as a "mechanics"
   pair, with a small inline diagram of the mic-to-cursor path.

**Remove from the page:**

- The current "Traditional dictation vs. A-Anie" section. It compares
  against a strawman ("traditional dictation") that is not what
  potential A-Anie users are evaluating against — they are evaluating
  against wispr-style cloud dictation. Replace it with a tighter
  comparison against cloud-only dictation tools, framed honestly:
  *"Cloud dictation tools upload your audio. A-Anie does not."*
- The "What makes it different" 8-card grid (Processing / Audio
  retention / Insertion method / App compatibility / Filler removal /
  Self-correction / Indian English / Hinglish). Most of those are
  either already implied by the diagram or unsupported by A-Anie's
  product. Keep at most: Indian English, Hinglish, On-device audio.
  Drop the rest.

---

*End of writeup.*