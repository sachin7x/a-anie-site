# Paper Diff — `guide.md` vs `guide2.md`

> The user pasted a second voice-dictation paper. The two papers describe the same architecture. This file records the overlap and the deltas. The architecture map (`ARCHITECTURE.md`) and the harness's provenance are unchanged unless a delta is large enough to reopen a decision.

## At a glance

| Aspect | `guide.md` (paper 1) | `guide2.md` (paper 2) | Delta? |
|---|---|---|---|
| Abstract framing | ASR + LLM refinement + vocab + app-aware formatting | Streaming ASR + NLP + vocab + context + cloud services | trivial — same components |
| Client platform scope | Tauri/Rust desktop, React Native mobile, native iOS/Android | Tauri/Rust desktop, React Native, Swift for iOS, Kotlin for Android | trivial — same set |
| Layers in the architecture | 6: client, audio, ASR, text gen, personalization, output | 6: client, audio, ASR, text gen, personalization+data, application integration | trivial — same count, slightly different naming |
| ASR math | `T_raw = ASR(A, L, V)` | `T_raw = ASR(A, L, V)` | identical |
| Text-gen math | `T_final = f(T_raw, C, S, V)` | `T_final = F(T_raw, C, S, V)` | identical |
| Semantic constraint | `Meaning(T_final) ≈ Meaning(T_raw)` | same | identical |
| Personal-vocab math | `V = {(w_i, p_i, c_i)}_{i=1..m}` | same | identical |
| Vocab examples | Postgres/PostgreSQL, Open A-I/OpenAI, Wispr Flow, M-C-P/MCP | Postgres/PostgreSQL, Open A I/OpenAI, M C P/MCP, Wispr Flow | same set, different spoken-form spellings |
| Privacy policy | `D_stored = ∅` when user opts out | `D_stored = ∅` when user opts out | identical |
| WER definition | `(S+D+I)/N` | `(S+D+I)/N` | identical |
| Latency decomposition | `L_total = L_capture + L_network + L_ASR + L_generation + L_insertion` | same | identical |
| Evaluation metrics | WER, semantic, formatting, latency, productivity | WER, semantic, formatting, latency, **correction accuracy**, productivity | **new metric: correction accuracy (§9.5)** |
| Limitations | 7 items, including LLM over-edit, network dependence, OS-specific insertion, model cost | 5 items, same themes + code-switching, federated learning | smaller list; same thrust |
| Future work | on-device ASR, code-switching, voice actions | same set, **plus** federated learning, confidence estimation, productivity platform integration | extras are speculative, not architecture |
| Concrete operational feature | — | **undo function, confidence indicators, transcript review** (§11, "should therefore provide") | **new product feature the user should see** |

## What this means for A-Anie

The two papers agree on the architecture. The second paper adds three concrete features to the *product* layer, not the *architecture*:

1. **Correction accuracy** as an evaluation metric. A-Anie does not currently measure this; F010 already says the "on-device" claim is text-only, not measured. No change required.
2. **Undo function** — A-Anie's desktop app should let the user undo a generated text before it replaces important content. This is consistent with the no-fabrication stance. The marketing site does not need a change; the desktop app's behaviour is the source of truth (and is out of scope for this repo).
3. **Confidence indicators** — same as above. A desktop-app feature, not a marketing-site feature.
4. **Transcript review** — the user should see and edit the transcript before insertion. Again, desktop-app territory.

None of these are new *architecture* — they are user-safety features at the same level as the "no fake transcription" constraint already codified in D001. The decisions file does not need a new entry. The marketing site's stance is unchanged.

## What this means for the harness

- The architecture map (`harness/docs/ARCHITECTURE.md`) does not need a revision — both papers map to the same A-Anie components.
- The provenance (`harness/state/facts.md`) does not need a new fact — the second paper is a *corroborating* source, not a new observation. If we ever need to cite the second paper in a future decision, the citation is `harness/docs/guide2.md §9.5`.
- The open question Q004 (Prime Agent paper) is *not* affected. The user did not paste the Prime Agent paper again.

## When to revisit

- If the desktop app ships an undo function or confidence indicator, those are decisions to record in `harness/state/decisions.md` (D008+) — but only when there is a marketing site copy change that needs defending, or when the desktop app source is in this repo.
- If A-Anie starts measuring correction accuracy and publishing a number, the no-fabrication rule (D001) requires the test methodology to be on disk. That is a future, larger conversation.
