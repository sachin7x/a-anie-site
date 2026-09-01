# A-Anie Design System — Prompt Pack

> Companion to `readme.md`. This is the **source of truth** for the visual language.
> All implementation must reference tokens defined here, never hardcode values.
> Generated: 2026-09-02.

## 0. Brand in one paragraph

A-Anie is a **system-level voice dictation layer for the messy way people actually speak** — built by one developer in Kishangarh, Rajasthan. The brand reads like a thoughtful independent product, not a SaaS startup. It is **warm + intelligent + technical + Indian + premium** without being stereotypical about any of those. The hero concept is *Speak → Understand → Edit → Write*, which must be visible within 5 seconds of landing.

## 1. Type system

**Rule:** editorial serif for emotional/product headlines; clean sans for UI; mono for technical labels only.

| Role | Family | Size (desktop / mobile) | Line-height | Weight | Letter-spacing | Use |
|------|--------|--------------------------|-------------|--------|----------------|-----|
| Display | Instrument Serif / Newsreader | 96 / 56 | 1.02 | 400 | -0.02em | Hero "It writes what you meant." |
| H1 | Instrument Serif | 72 / 44 | 1.05 | 400 | -0.02em | Section openers |
| H2 | Instrument Serif | 48 / 32 | 1.10 | 400 | -0.015em | Section titles |
| H3 | Outfit | 24 / 20 | 1.25 | 600 | -0.005em | Card titles, sub-sections |
| Body L | Outfit | 20 / 18 | 1.55 | 400 | 0 | Hero supporting sentence |
| Body | Outfit | 17 / 16 | 1.55 | 400 | 0 | Default paragraph |
| Small | Outfit | 14 / 14 | 1.45 | 400 | 0 | Captions, meta |
| Label | Outfit | 12 / 12 | 1.3 | 600 | 0.08em | Eyebrow text (always uppercase + tracked) |
| Mono | JetBrains Mono | 13 / 13 | 1.4 | 400 | 0 | Technical labels, code, timestamps, data points |
| Button | Outfit | 15 / 15 | 1 | 500 | 0 | All CTAs |

**Pairing rules:**
- Serif italic (`<em>`) inside an otherwise roman serif headline is a signature move. Use it for the second clause of the hero: *"It writes what you meant."* and the Anjali story opener: *"Too much."*
- Mono is only for technical receipts (e.g. `45 WPM`, `Next.js 14`, `arg[/]on2id`, `vercel.json`). Never for body copy.
- Labels (eyebrow text) are always uppercase, 0.08em tracking, 12px. They go above section titles to set up the topic.

## 2. Color tokens

Existing tokens in `public/styles.css` are correct. **Do not add new colors.** Use them by role:

| Token | Hex | Role | Allowed uses | Forbidden uses |
|-------|-----|------|--------------|----------------|
| `--bg-cream` | `#FDFCE8` | Page background, light surface | All light backgrounds, cards on light | Never as text, never on dark |
| `--ink` | `#131313` | Primary text, primary CTA bg | Body text, primary buttons, brand mark | Never on cream as decorative fill |
| `--ink-2` | `#1a1a1a` | Secondary text on dark | Footer on dark, dark section text | Never on light |
| `--bg-dark` | `#0F0F0F` | Dark section background, code | Privacy section, code blocks, footer | Never on light |
| `--accent-lav` | `#E4CCFA` | Soft accent fill, illustration highlight | Hover states, illustration accent, soft chips | Never on dark as foreground |
| `--accent-lav-line` | `#B98BE8` | Accent line/stroke | Illustration lines, key underlines, focus rings | Never as background fill |
| `--text-muted` | `#5A5A55` | Secondary body text | Captions, helper text, meta | Never as primary body |
| `--ghost` | `#C9C9C0` | Dividers, disabled | `<hr>`, input borders, table rules | Never as text |
| `--amber` | `#F5B04C` | Honest "early/beta" badge, "self-reported" | Status pills, self-disclosure callouts | Never for primary actions |
| `--saffron` | `#E8A33D` | Hero illustration accent, Rajasthan nod | Hero only, single illustration stroke | Never in UI, never as button |
| `--india-green` | `#1F5C3D` | "Verified" / "no fake" indicator | On-device labels, verified-data pills | Never as primary brand color |

**Contrast rules (WCAG AA):**
- `--ink` on `--bg-cream` = 16:1 ✓
- `--ink-2` on `--bg-dark` = 17:1 ✓
- `--text-muted` on `--bg-cream` = 7.2:1 ✓ (large text + body)
- `--accent-lav-line` on `--bg-cream` = 3.4:1 (decorative only, never body)
- `--amber` on `--bg-cream` = 2.4:1 (large/bold only, never small text)

**Anti-palette (forbidden):** any purple→pink gradient, cyan/teal as brand, neon green, neon blue, "AI purple" `#8B5CF6`. These are off-brand.

## 3. Spacing & rhythm

8px base. All vertical rhythm in multiples of 8.

| Token | Value | Use |
|-------|-------|-----|
| `space-1` | 8px | Inline gap between icon and text |
| `space-2` | 16px | Inside small cards, between form fields |
| `space-3` | 24px | Card padding (mobile) |
| `space-4` | 32px | Card padding (desktop), gap between related elements |
| `space-6` | 48px | Gap between siblings in a row |
| `space-8` | 64px | Section internal padding (mobile) |
| `space-12` | 96px | Section internal padding (desktop) |
| `space-16` | 128px | Major section break (mobile) |
| `space-20` | 160px | Major section break (desktop) |
| `space-24` | 192px | Hero top/bottom padding (desktop) |

**Container widths:**
- Reading column (blog): 680px
- Standard: 1120px
- Wide (OG/hero): 1200px
- Maximum: 1400px (xl)

**Vertical section rhythm pattern:** `space-20 → section content → space-20` is the standard. Hero gets `space-24 → content → space-20`.

## 4. Motion language

Six named motions. Every animation in the site maps to one of these.

| Motion | Trigger | Duration | Easing | What moves | What doesn't |
|--------|---------|----------|--------|------------|--------------|
| `heroEnter` | Page load | 600ms | `cubic-bezier(.22,.61,.36,1)` | Headline (translateY 16px → 0, opacity 0 → 1, stagger 80ms per line), supporting sentence, CTAs | No bounce, no scale > 1.02 |
| `textReveal` | Scroll into view | 400ms | `cubic-bezier(.22,.61,.36,1)` | Heading, subhead, body — opacity 0 → 1, translateY 12px → 0 | No letter-by-letter |
| `waveformPulse` | Continuous, demo only | 1200ms loop | `ease-in-out` | 5-7 vertical bars, height 8-24px alternating | The cursor, the text |
| `demoStep` | User clicks tone/language | 250ms crossfade | `ease` | Input card → transformation card → output card. The transformation card is briefly highlighted (border `--accent-lav-line` for 400ms) | The layout positions (no reflow) |
| `sectionFade` | Section enters viewport | 500ms | `cubic-bezier(.22,.61,.36,1)` | Whole section: opacity 0 → 1, translateY 24px → 0 | No scale, no rotate |
| `buttonFeedback` | Hover / active | 150ms | `ease-out` | Background color shift (hover), translateY 1px (active) | No scale on hover |
| `cardHover` | Pointer over interactive card | 200ms | `ease-out` | Border color `--ghost` → `--accent-lav-line`, translateY -2px | No shadow, no glow |

**Forbidden motions:** perpetual rotation, parallax scroll, 3D transforms, fade-in-then-pulse, anything that loops more than 1.5s without user action.

**Reduced motion:** under `@media (prefers-reduced-motion: reduce)`, set every duration to 0 and every transform to `none`. Already partially implemented — finish the audit.

## 5. Component inventory

For each major component, one rule of "what elevates it."

| Component | Purpose | Bootstrap classes | Elevation rule |
|-----------|---------|--------------------|----------------|
| Navbar | Brand, nav, primary CTA | `.navbar.navbar-expand-lg.bg-cream` | The Download CTA on the right is the only solid-black button; everything else is text-only |
| Hero | Big promise, demo | `.container > .row` with display H1 + supporting + CTAs | The **interactive demo is the centerpiece** — not a static image |
| Compat | "Works everywhere" | `.row.g-3` of small icons | Icons are 24px mono-line, no fill, 4-language label only when in view |
| HowItWorks | 3-step flow | `.row > .col-md-4` cards | The middle card (Understand) gets `--accent-lav` background; left and right are outlined |
| Languages | Tabs of 7 langs | `.nav.nav-pills` + active panel | Clicking a language **animates a sample transformation** — not a static list |
| Personalization | Tone switcher | Same as Languages, 3 tones | Same: animate a "uh yeah that seems fine" → "That works on my end" |
| Demo (the "watch A-Anie think" section) | The transformation showcase | Custom (no Bootstrap card grid) | Each step (filler / self-correction / structure) is a horizontal line of bars that fill left → right, then collapses the input and reveals the output |
| Comparison table | A-Anie vs Wispr vs OS | `.table.table-borderless` with `.table-light` on odd rows | Wispr column has `--amber` "not independently verified" footnote where applicable |
| Stats | "Honest numbers" | `.row` of 3 stat blocks, each with mono number + label | All numbers are self-labeled: "self-reported", "internal measurement", "early" |
| Testimonials | "No fake social proof" | A single full-width block, not a card grid | The honest statement: *"Built by one developer. Used by early testers. Still earning every number."* |
| Founder / Anjali | Kishangarh origin | 2-column with portrait placeholder + story | The portrait is a hand-drawn SVG (Kishangarh miniature aesthetic), never a stock photo |
| Pricing | Free / early-access | One centered card, not 3-column grid | Includes a "no fake numbers" disclaimer: "Pricing will be public as soon as it's decided." |
| FAQ | Real concerns | `.accordion` | 8-12 questions, all answering real skepticism (offline, languages, privacy, who built it) |
| Privacy | "Data, plainly explained" | Dark section (`.bg-dark.text-light`) | Lists in mono, each row starts with a literal answer, no legalese |
| Contact | Form + status | `.form` with custom error state | Submits to `POST /api/v1/contact` (verified working post-slice-3) |
| Footer | Minimal | `.container.text-muted` | 4 columns: Product / Company / Legal / Built by. No social icons (we don't have them) |

## 6. Illustration brief (one paragraph per SVG)

All 9 illustrations: `viewBox="0 0 120 120"`, stroke 1.5px, round caps, single `--accent-lav` accent, no fills except the single accent, no shadows/filters/gradients/emoji/text-inside. ~40% empty space. Hand-written SVG.

**hero.svg** — A microphone on the left, a single waveform in the middle (3-5 vertical bars of varying height), and a cursor + short text on the right. All in a single 1.5px stroke. The waveform bars are `--ink`, the cursor is `--ink`, and one of the waveform bars (the tallest) is filled with `--accent-lav`. No text inside.

**intent.svg** — Three concentric speech-bubble outlines (rounded rectangles with a small tail at bottom-left), each smaller than the last, all `--ink` except the innermost which is filled `--accent-lav`. Represents layered understanding.

**personalization.svg** — A single horizontal waveform with varying amplitude, but the center of the waveform is highlighted with `--accent-lav` (a single bar of the wave is filled). 7-9 vertical bars total.

**languages.svg** — Three distinct glyphs from different scripts (e.g. `अ` Devanagari, `ع` Arabic, `中` Han), each in a circle, all in `--ink`. The middle one is filled `--accent-lav`.

**injection.svg** — A small rounded rectangle representing a text field, with a cursor `|` inside it on the left, and a horizontal arrow flow line going from off-canvas left into the rectangle. The arrow is `--accent-lav`, the rectangle outline and cursor are `--ink`.

**founder.svg** — A simple desk silhouette (a horizontal line for the desk top, two small legs) with a single small dot above (a person, abstracted to a circle). The desk is `--ink`, the dot is `--accent-lav`. A tiny line at top suggests a hanging light.

**privacy.svg** — An envelope shape (rectangle + triangular flap), drawn in `--ink` 1.5px stroke. The flap fold is a single `--accent-lav` line.

**architecture.svg** — Five small circles connected by 4 short lines, arranged horizontally. The third circle is filled `--accent-lav`, the others are `--ink` outlines.

**cta.svg** — A cursor arrow pointing into a frame (the injection rectangle without the arrow), rotated 45° so it points down-right into a corner. Cursor in `--ink`, frame outline in `--ink`, a single `--accent-lav` dot at the cursor tip.

## 7. OG image brief

**Dimensions:** 1200×630 PNG. **Background:** `--bg-cream`. **No gradients, no shadows, no filters.**

**Layout:**
- Top-left: small A-Anie wordmark in `--ink` (Instrument Serif, 48px).
- Below wordmark: italic serif, 28px, `--text-muted`: "It writes what you meant."
- Center-right: a single horizontal waveform (8-10 vertical bars, varying height, all `--ink`) transitioning into a cursor + 4 short horizontal lines representing text (`--ink`). One of the waveform bars is filled `--accent-lav`.
- Bottom: small mono text in `--text-muted`: `voice-to-text.aanie.com`

**Forbidden:** gradients, multiple fonts, stock illustration, "AI-powered" tagline, more than 6 words of body text.

## 8. Copy voice — 10 rules

1. Indian without being stereotypical — never use "namaste", "chai", "rupee emoji", or "jugaad".
2. No SaaS jargon — never use "synergy", "leverage", "unlock", "supercharge", "revolutionary".
3. No fake social proof — never invent users, testimonials, or numbers.
4. Honest about being early — "early testers", "still earning every number", "self-reported" are features, not bugs.
5. Confident but not hyped — make claims quietly. Let the product speak.
6. Specific > generic — "Wednesday works better." not "more efficient communication."
7. Show the messy input — every demo starts with how people actually speak, not polished text.
8. Use `→` arrows in UI to mean "becomes" (e.g. `uh yeah → That works.`).
9. Monospace for honesty markers — `45 WPM [self-reported]`, `Next.js 14`, etc.
10. No emoji in copy. Period.

**Sample microcopy:**
- Navbar CTA: "Download" (not "Get Started", not "Try Free")
- Hero eyebrow: "System-level voice dictation"
- Hero supporting: "Speak naturally. A-Anie cleans up what you meant. The finished text appears wherever your cursor already is."
- Personalization tab labels: "Formal" · "Casual" · "Very casual" (not "Professional" · "Friendly" · "Casual")
- Stats section opener: "Honest numbers, not testimonials"
- Testimonial section opener: "Early product, building in public"
- Founder section opener: "Built in Kishangarh, Ajmer, Rajasthan"
- Privacy section opener: "Data, plainly explained"
- Contact form success: "Message sent. Sachin will reply soon." (matches backend response)
- Pricing: "Free tier. No card. No trial. No email gate." (current claim, verify still true)
- Final CTA heading: "Stop typing. Start saying." (keep the existing line)
- Final CTA subhead: "Mac · Windows · Linux · Chrome extension"

## 9. Anti-patterns (do not do)

- ❌ Purple→pink gradients (forbidden color palette)
- ❌ Cyan/teal as a brand color
- ❌ Glassmorphism, frosted glass, backdrop-blur on cards
- ❌ Card-grid-everything layout (every section a 3×3 grid)
- ❌ Stock photos of diverse teams, laptops on desks, microphones
- ❌ Emoji in copy or illustrations
- ❌ Fake testimonials with stock headshots
- ❌ Fabricated user counts, NPS, retention, MAU
- ❌ "AI-powered" as the tagline (it's a feature, not a positioning)
- ❌ Cliché neural-network / brain / circuit illustrations
- ❌ "Revolutionary", "game-changing", "next-generation"
- ❌ Competitor bashing
- ❌ Perpetual rotation, parallax scroll, 3D transforms
- ❌ More than 2 typefaces visible in any single view (we use 3: serif, sans, mono)
- ❌ Neon green, neon blue, neon anything
- ❌ Footers with 6+ social icons when we have no social presence

## 10. Open questions (decide before implementation)

1. **Download CTA**: real link or "Coming soon" badge? Current state: `href="#"`. Decision needed.
2. **Founder portrait**: hand-drawn SVG (Kishangarh miniature style) vs. a literal outline vs. no portrait at all?
3. **Comparison table**: include Wispr Flow with cited info (we have their public pricing/features), or omit competitor and just compare "Built-in OS dictation" + "Other AI dictation tools" + "A-Anie"?
4. **Languages section**: show all 7 languages with sample transformations, or pick 3 (English, Hinglish, Hindi) and have a "more coming" footnote?
5. **Pricing**: keep the "Free tier. No card. No trial. No email gate." if still true, or pivot to "Waitlist" if not?
6. **Blog post**: publish as `content/solo-developer-journey.md` (readme §13 deliverable), or skip until the founder has time to write it authentically?
