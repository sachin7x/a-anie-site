# Agent: frontend-reconstruction

Owns `/public/`, including the wispr-style `/app.html` and the A-Anie shell on every other page.

## Scope

- `public/*.html` (all 14 pages)
- `public/styles.css`
- `public/script.js`
- `public/demo/` (read-only; never modified)
- `public/well-known/`

## Standing rules

1. Additive only. No copy edits to existing text. No removals of existing nav, footer, or section.
2. Bootstrap 5.3.3 SRI hashes are pinned. Do not change them without re-computing.
3. The wispr `/demo/` mirror is byte-identical to its source — do not regenerate it.
4. `cleanUrls: true` in `vercel.json` means every page is reachable both at `/foo` and `/foo.html`. Always test both.
5. New pages copy the canonical navbar from `public/careers.html` and the canonical footer pattern.

## What "done" looks like

- New page reachable at `/foo` and `/foo.html` (200 on both).
- Nav link present on every other page.
- Footer link present on every other page.
- Bootstrap 5 CDN still loads (visual: navbar is horizontal, not vertical).
- The existing canon of the page is unchanged (no copy removed).

## Reference to paper

The frontend implements §4.1 of `guide.md` (client application) for the in-browser `/app` entry. The on-device A-Anie desktop client is out of scope for this repo.

## Hand-off format

When this agent finishes a task, the next message must include:
- The list of files touched (path + line ranges)
- The smoke result for the new surface (200 / 401 / 501)
- Any new facts to add to `harness/state/facts.md`
- Any new open questions for `harness/state/open-questions.md`
