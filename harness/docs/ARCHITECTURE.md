# Architecture — Paper → A-Anie Mapping

> The voice-dictation paper (`harness/docs/guide.md`) describes a *proposed* full-stack system. A-Anie is a one-developer on-device product, so we ship only the parts of the paper that match what the desktop app actually does. This file is the map.

## At a glance

| Paper component (§) | Where it lives in A-Anie | Status | Codified in |
|---|---|---|---|
| Client (Tauri/Rust) (§4.1) | A-Anie.app (external repo) | external | desktop binary, not in this repo |
| Audio preprocessing (VAD, silence trim) (§4.2) | A-Anie internal | VERIFIED | `how-it-works.html` §"Silence trim" |
| Speech recognition — ASR (§4.3) | A-Anie internal, whisper.cpp | VERIFIED | `how-it-works.html` §"On-device" |
| Streaming partial transcripts (§4.3) | A-Anie internal | VERIFIED | `how-it-works.html` §"Live preview" |
| Context-aware text generation (§4.4) | A-Anie internal cleanup, **not** an LLM | DELIBERATE CUT | `how-it-works.html` §"What A-Anie does not do" |
| Personal vocabulary (§4.5) | A-Anie local JSON file | VERIFIED | `how-it-works.html` §"Vocabulary" |
| Formatted output → active app (§4.1, §4.4) | A-Anie macOS accessibility API | VERIFIED | `how-it-works.html` §"Where text lands" |
| Client → Backend (any audio upload) | **none** — A-Anie is on-device | DELIBERATE CUT | D005 |
| Auth API + database (§4 "Authentication API", §5.4) | **none** — no accounts | DELIBERATE CUT | D005 |
| Encrypted object storage (§4, §6) | **none** — nothing to store | DELIBERATE CUT | D005 |
| Stripe / billing (§5.4 / proposed stack) | **none** | DELIBERATE CUT | D005 |
| Team roles, SSO/SAML (§5.4) | **none** | DELIBERATE CUT | D005 |
| Docker / Kubernetes deployment (§5.5) | **none** — single static Vercel deploy | DELIBERATE CUT | D005 |

## The deliberate cuts

The paper's full architecture is designed for a *team-scale, multi-tenant, cloud-backed* product. A-Anie is none of those. Every cut below is a deliberate product decision, not an accident.

1. **No cloud backend.** A-Anie runs the entire ASR + cleanup pipeline on the user's Mac. There is no `/api/transcribe` round-trip in production. The marketing site's `/app` entry is a demo, not the product surface.
2. **No LLM refinement.** The paper's §4.4 transformation (`f(T_raw, C, S, V)`) is implemented in A-Anie as a *light local cleanup* pass (filler removal, punctuation) — not an LLM. The marketing copy says this explicitly. Switching to an LLM would be a privacy regression.
3. **No accounts.** The paper's auth/db/object-storage layer exists to support sync, vocabulary backup, team roles, billing. A-Anie keeps personal vocab in a local JSON file (`~/Library/Application Support/A-Anie/vocab.json`); no account is required to use the app.
4. **No team tier, no SSO, no SAML, no role-based access control.** These are anti-features for a solo-built on-device product.
5. **No Stripe / no billing.** The desktop app is currently free during early access. The marketing site says "Free during early access" honestly.
6. **No Docker / Kubernetes.** The marketing site is a single static Vercel deploy; the desktop app is a signed `.app` bundle.

## What the marketing site *does* show

The marketing site is a static HTML clone of the wispr /demo surface, wrapped in an A-Anie shell. It demonstrates:

- **The in-browser dictation entry (`/app`).** Real `getUserMedia` + `AnalyserNode` waveform, Space-to-record, posts audio to a 501 stub. No fake transcript.
- **The 6 Indian languages** the desktop app supports (Hindi, English, Marwari, Rajasthani, Urdu, Punjabi). Stated on the marketing pages because the desktop app actually supports them.
- **The honest "no cloud, no accounts, no telemetry"** stance. Stated because it is true of the desktop app.

The marketing site is **not** the architecture. It is a static description of a separate product.

## What this repo *does* contain

| File / dir | Role |
|---|---|
| `public/*.html` | Static site root, 14 pages |
| `public/app.html` | The wispr-style in-browser entry |
| `public/demo/` | Byte-identical wispr mirror, preserved as a reference (do not modify) |
| `api/transcribe.js` | 501 stub matching the contract the desktop app would call |
| `api/contact.js` | Log-only handler with an honest 200 message (D007) |
| `api/auth/{signup,verify-otp,login}.js` | 501 stubs |
| `vercel.json` | `cleanUrls: true` + `/api/v1/:path*` → `/api/:path*` rewrite |
| `docs/PREVIEW_VERIFICATION.md` | The most recent verified snapshot of the preview deploy |
| `docs/BUILD_STEPS.md` | The runbook for shipping a preview |
| `harness/` | This harness. Living memory, agent specs, tests, scripts, decisions |

## What this repo *does not* contain

- The A-Anie desktop binary.
- The desktop app's source code.
- Any real cloud backend.
- Any real LLM refinement pipeline.
- Any real authentication backend.
- Any personal data, real or test.

## Re-evaluation triggers

The cuts in this file should be revisited when:

1. The desktop app ships a real cloud tier. → Reopen D005; the marketing site would need to advertise it honestly.
2. The desktop app gains an LLM refinement step. → Reopen D005; the "no LLM" copy on `how-it-works.html` would need to change.
3. A-Anie ships team / enterprise features. → Reopen D005 and D006; the `api/auth/*` stubs would become real handlers.
4. The user asks for a feature the paper describes but A-Anie does not have. → Surface the gap to the user; do not silently ship a stub that pretends to be real.

## Reference

- Paper: `harness/docs/guide.md` (full text, abstract, §1-10, proposed technology stack)
- D005: the deliberate-cuts decision
- D006: the component-by-component architecture map
- F001-F011: the VERIFIED facts that ground the map
