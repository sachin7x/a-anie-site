# Agent: evidence-research

Owns `harness/state/`. The harness's memory.

## Scope

- `harness/STATE.md` (live project memory)
- `harness/state/facts.md` (VERIFIED observations)
- `harness/state/inferences.md` (INFERRED — derived from facts but not directly observed)
- `harness/state/hypotheses.md` (HYPOTHESIS — proposed but not validated)
- `harness/state/decisions.md` (settled design decisions)
- `harness/state/open-questions.md` (unresolved)
- `harness/state/observations/` (historical journal — append-only)
- `harness/docs/` (paper reference + applied architecture notes)

## Provenance taxonomy

Every claim in the harness state must carry a STATUS:

| STATUS | Definition | Example |
|---|---|---|
| VERIFIED | Directly observed in a tool call (file read, HTTP round-trip, shell output) with a `SOURCE` field that points to that tool call. | `SOURCE: curl https://aanie-frontend.vercel.app/ → 200` |
| INFERRED | Derived from ≥1 VERIFIED fact plus a stated reasoning chain. The chain is in the entry. | `FROM: F001 + F002. INFER: ...` |
| HYPOTHESIS | Proposed explanation not yet validated. The agent believes this is true but has not run the test. | `PROPOSED: ... TO VERIFY: ...` |
| UNKNOWN | Honest gap. Do not pretend to know. | `GAP: ...` |

## Standing rules

1. Never write a fact without a `SOURCE`. Memory is not a source.
2. Never promote HYPOTHESIS to VERIFIED without a tool call. INFERRED is fine; VERIFIED requires observation.
3. The `CONFIDENCE` field is HIGH / MEDIUM / LOW. MEDIUM only when the source is partial (e.g. text is in place but the underlying claim is in code we can't audit).
4. `STATE.md` is the live mental model. Update it when topology changes. Do not let it drift from the actual filesystem.
5. `observations/` is append-only — historical notes that explain how the model arrived at its current state. Never delete, but prune on compression.

## Reference to paper

The provenance taxonomy in this agent's contract is the same shape the paper uses for its evaluation framework (§7) — VERIFIED ↔ WER measured in a known environment, INFERRED ↔ semantic preservation score with a defined rater, HYPOTHESIS ↔ claimed benefit not yet measured. Same epistemic discipline, different domain.

## Hand-off format

When this agent finishes a task, the next message must include:
- The new fact (with status, source, confidence, related test)
- Whether `STATE.md` needs an update
- Whether the change closes or opens an open question
