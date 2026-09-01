# A-Anie UI Implementation Roadmap (15 slices)

> UI-only work. **No content deletion.** Existing copy, FAQ, founder story, pricing, footer, statistics, testimonials, all preserved verbatim. Visual polish, layout refinement, motion, accessibility only.
> Source of truth: `design/DESIGN_PROMPT.md`. Verification: `npm run smoke:prod` (7/7) and `npm run smoke:api` (5/5) must remain green.
> Generated: 2026-09-02.

## 0. Files in scope

7 pages: `public/index.html`, `story.html`, `how-it-works.html`, `pricing.html`, `login.html`, `data-controls.html`, `terms.html`. One stylesheet: `public/styles.css`. Tokens already defined (do not add new ones, do not rename): `--bg-cream, --ink, --ink-2, --bg-dark, --accent-lav, --accent-lav-line, --text-muted, --ghost, --amber, --saffron, --india-green, --font-display, --font-ui, --font-mono, --ease, --radius-card (16px), --bs-primary, --bs-body-font-family`. Bootstrap 5.3.3 with verified SRI hashes.

## 1. Sequence overview

| # | Slice | Files | Verification |
|---|-------|-------|--------------|
| 1 | Token & spacing scale (formalize) | `public/styles.css` | grep verifies no new hardcoded hex; npm run smoke:prod 7/7 |
| 2 | Typography scale (Display/H1/H2/H3/Label/Mono) | `public/styles.css` | DOM inspection: hero H1 uses --font-display; smoke 7/7 |
| 3 | Section rhythm (space-20/24 hero, space-12 section padding) | `public/styles.css` | Visual; smoke 7/7 |
| 4 | Navbar polish (sticky, active state, focus ring) | `public/styles.css`, all 7 pages | Tab key walks links visibly; smoke 7/7 |
| 5 | Hero section elevation (demo centering, demo CTA contrast) | `public/index.html` (markup only, no copy edits), `public/styles.css` | Hero <h1> = --font-display; smoke 7/7 |
| 6 | Compat "Works everywhere" grid | `public/index.html`, `public/styles.css` | Icons 24px mono-line; smoke 7/7 |
| 7 | How-it-works step cards (middle card accent-lav) | `public/how-it-works.html`, `public/styles.css` | All step copy preserved; smoke 7/7 |
| 8 | Languages & Personalization tab switcher animation | `public/script.js` (animation logic only), `public/styles.css` | Clicking tab updates panel; smoke 7/7 |
| 9 | "Watch A-Anie think" demo section | `public/index.html`, `public/styles.css` | Step copy preserved; smoke 7/7 |
| 10 | Comparison table polish | `public/index.html`, `public/styles.css` | Wispr cells have --amber footnote; smoke 7/7 |
| 11 | Stats "honest numbers" treatment | `public/index.html`, `public/styles.css` | Each number self-labeled; smoke 7/7 |
| 12 | Testimonials → "no fake social proof" | `public/index.html` (markup only) | Existing copy preserved; smoke 7/7 |
| 13 | Pricing card elevation | `public/pricing.html`, `public/styles.css` | Existing "Free tier" copy preserved; smoke 7/7 |
| 14 | Founder/Anjali editorial layout | `public/story.html`, `public/styles.css` | All Anjali text preserved; smoke 7/7 |
| 15 | Motion + reduced-motion audit | `public/styles.css` | prefers-reduced-motion collapses animations; smoke 7/7 |

## 2. Per-slice spec (first 3)

### Slice 1 — Token & spacing scale formalize
- **Goal:** Add named spacing tokens (8pt scale) to `styles.css` without changing existing tokens.
- **Files:** `public/styles.css`
- **Edits:**
  - Add inside `:root` (after existing tokens): `--space-1: 8px`, `--space-2: 16px`, `--space-3: 24px`, `--space-4: 32px`, `--space-6: 48px`, `--space-8: 64px`, `--space-12: 96px`, `--space-16: 128px`, `--space-20: 160px`, `--space-24: 192px`. Section 3 of `design/DESIGN_PROMPT.md`.
  - Add `--radius-pill: 999px`, `--radius-input: 8px`, `--radius-card: 16px` (existing).
  - Add `--shadow-card-hover: 0 4px 12px rgba(19, 19, 19, 0.06)` (subtle, single shadow).
  - Do NOT rename or remove any existing token.
- **Verification:** `grep -E "^\s*--" public/styles.css | wc -l` shows new tokens added; no existing token name changed; `npm run smoke:prod` still 7/7.
- **Preservation:** No content change.
- **Risk:** Low. Adding tokens doesn't break anything; downstream slices consume them.

### Slice 2 — Typography scale
- **Goal:** Apply the type table from `design/DESIGN_PROMPT.md` §1 across the site using Bootstrap utility extensions.
- **Files:** `public/styles.css`
- **Edits:**
  - Add `h1, h2 { font-family: var(--font-display); font-weight: 400; letter-spacing: -0.02em; line-height: 1.05; }`
  - `h3, h4, h5, h6 { font-family: var(--font-ui); font-weight: 600; }`
  - `.eyebrow { font-family: var(--font-ui); font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.08em; }`
  - `.mono-label { font-family: var(--font-mono); font-size: 13px; }`
  - Do NOT change `<h1>`, `<h2>`, `<h3>` tags in any HTML file.
- **Verification:** DOM: hero H1 renders in Instrument Serif (or fallback); `npm run smoke:prod` 7/7.
- **Preservation:** No content change. Existing HTML tags unchanged.
- **Risk:** Medium. Bootstrap's default H1 styles may need `!important` or higher specificity; verify visually.

### Slice 3 — Section rhythm
- **Goal:** Apply vertical rhythm so every section has predictable breathing room.
- **Files:** `public/styles.css`
- **Edits:**
  - `section { padding-block: var(--space-12); }` (96px default)
  - `section.hero, section.py-5.bg-light:first-of-type { padding-block: var(--space-20) var(--space-12); }` (160 top, 96 bottom)
  - `section + section { border-top: 1px solid var(--ghost); }` (hairline divider between sections, very subtle)
  - Add `:focus-visible { outline: 2px solid var(--accent-lav-line); outline-offset: 2px; }` global focus ring (for slice 4 onward)
- **Verification:** Visual rhythm; `npm run smoke:prod` 7/7.
- **Preservation:** No content change.
- **Risk:** Low. Section padding already exists via Bootstrap utilities; this is a refinement.

## 3. Slice catalog (4-15)

**Slice 4 — Navbar polish.** Sticky positioning with `var(--bg-cream)` background, 1px `--ghost` bottom border, focus ring on tab. Active link gets `aria-current="page"` set per page (manual). Mobile hamburger already present; verify `aria-expanded` toggles. Verification: tab key walks through links with visible focus ring.

**Slice 5 — Hero elevation.** Hero `<h1>` confirmed as `var(--font-display)`. Primary CTA "Download" button: solid `var(--ink)` background, `var(--bg-cream)` text, 16px 32px padding, `--radius-pill` corners. Secondary CTA "See how it works" is text-only with underline. Spacing above the demo card gets `var(--space-6)` so the demo breathes. No copy changes.

**Slice 6 — Compat grid.** The 6-8 "works everywhere" icons in `index.html` get a clean `.row.g-3` of small icon cards. Each icon is 24px monoline (no fill). 4-letter label below in `var(--text-muted)`. No card backgrounds; just spacing. Verification: visual.

**Slice 7 — How-it-works cards.** The 3 step cards (`<div class="col-md-4">`). The middle one ("Understand") gets `var(--accent-lav)` background; left and right outlined. No copy edits. All step descriptions preserved verbatim.

**Slice 8 — Tab switcher animation.** Bootstrap's nav-pills already render. Add a 250ms crossfade (`sectionFade` motion from §4) when switching languages/tones. Use `transition: opacity 250ms var(--ease)` on `.tab-pane.active`. Respect `prefers-reduced-motion: reduce` (collapse to 0ms). No copy change.

**Slice 9 — "Watch A-Anie think" demo.** The transformation showcase. Render as 3 horizontal lines of progress bars (filler, self-correction, structure) that fill left→right on scroll, then collapse the input and reveal the output. Uses `var(--accent-lav-line)` for the progress fill. Existing transformation text preserved verbatim. No copy change.

**Slice 10 — Comparison table.** A-Anie vs Wispr Flow vs OS dictation. Wispr cells get a `var(--amber)` "not independently verified" footnote where applicable. Header row `var(--ink)` text on `var(--bg-cream)`. Odd rows get a `--ghost` hairline. Do NOT invent competitor specs; mark each Wispr claim with the source it came from (or omit if unverifiable). Existing comparison rows preserved.

**Slice 11 — Honest stats.** Each of the 3 stat blocks (45 WPM, 220 WPM, and the third one) is labeled with mono small text: `[self-reported]`, `[internal measurement]`, `[early]`. The number itself stays in `var(--font-display)` for editorial weight. No copy change. No fake numbers added.

**Slice 12 — Testimonials block.** The existing "Early product, building in public" copy is preserved. The block becomes a single full-width centered quote, not a card grid. Use `var(--font-display)` italic for the quote. No card-grid-everything. No new testimonials.

**Slice 13 — Pricing card.** Existing "Free tier. No card. No trial. No email gate." copy preserved. Card uses `var(--radius-card)`, subtle hover lift, `--accent-lav-line` 1px border. The placeholder text from `pricing.html:131` ("The card below will be filled in as soon as they're decided — no rush, no fake numbers.") stays.

**Slice 14 — Anjali / story.** The Kishangarh narrative already exists. Layout: 2-column with portrait placeholder (small SVG circle in `var(--accent-lav)`) + story text. Reading column constrained to `max-width: 65ch`. No copy edits. The `<em>Too much.</em>` italics get `var(--font-display)`.

**Slice 15 — Motion & reduced-motion audit.** Apply the 7 named motions from §4. `prefers-reduced-motion: reduce` collapses all durations to 0 and all transforms to `none`. Audit existing animations (navbar transitions, button hover) for consistency. No copy change. Final smoke run.

## 4. Per-slice preservation note (one line per slice)

1. CSS only.
2. CSS only.
3. CSS only.
4. All existing nav links and logo unchanged.
5. All hero headline, subtext, and CTA labels unchanged.
6. All compat label text unchanged.
7. All step copy unchanged.
8. All language/tone tab labels unchanged.
9. All transformation copy unchanged.
10. All comparison rows preserved.
11. All existing numbers preserved.
12. All testimonial copy preserved.
13. All pricing copy preserved.
14. All founder story text preserved.
15. CSS only.

## 5. What we will NOT do

- No content deletion. Existing copy, FAQ answers, founder story, statistics, testimonials, pricing, footer links all preserved verbatim.
- No new sections. We polish what's there.
- No new dependencies. Bootstrap 5.3.3 is the only external.
- No new pages. Only the existing 7.
- No new colors. Existing tokens only.
- No fabricated numbers, testimonials, or competitor specs.
- No changes to `api/`, `vercel.json`, `package.json`, `slices/`, `illustrations/`, `design/` content.
- No deployment. Local smoke verification only.

## 6. Open questions (decide before slice 1-3)

1. **Section dividers.** Should adjacent sections have a 1px `--ghost` hairline between them (adds structure, may add visual noise), or just rely on whitespace? Default: hairline.
2. **Comparison table.** Include Wispr Flow (with cited info from their public site) or restrict to "OS dictation + generic AI tools + A-Anie"? Default: include Wispr with citations.
3. **Hero CTA.** "Download" button — does it link to a real download page or stay `href="#"` with a "coming soon" badge? Default: keep `href="#"` and add a `disabled` style + small "soon" badge in `var(--amber)`.
4. **Bootstrap specificity.** Apply our typography overrides with `:where()` (zero specificity) or direct selectors (will override Bootstrap)? Default: `:where()` so Bootstrap utilities still work.

## 7. Verification protocol

After every slice:
1. `npm run smoke:prod` — must remain 7/7.
2. `npm run smoke:api` — must remain 5/5 (slice 3 fix should hold).
3. Visual check on the 3 main pages: `/`, `/how-it-works`, `/pricing`.
4. No `git diff` of HTML copy in any commit. Diff should be CSS-only or `script.js` only.

## 8. Out of scope (deferred to future slices 16+)

- Blog post (`content/solo-developer-journey.md`).
- Comparison content doc (`content/comparison.md`).
- Investor presentation (`presentation/a-anie-product-vision.md`).
- OG image regeneration to drop gradients.
- Adding an actual download flow.
- New illustrations beyond the 9 in `public/illustrations/`.
