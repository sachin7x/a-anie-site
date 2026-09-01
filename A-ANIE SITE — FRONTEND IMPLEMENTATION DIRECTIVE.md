# A-ANIE SITE — FRONTEND IMPLEMENTATION DIRECTIVE

Repository:

`/Users/sachin/Movies/a-anie (1)/a-anie-site/`

The existing `readme.md` is the primary product/design specification. Treat it as authoritative for the visual language, positioning, claims, accessibility, performance, privacy, and implementation quality bar.

## OBJECTIVE

Transform the existing A-Anie site into the complete production-quality product website described in `readme.md`.

This repository is not only a landing page.

The final site must include:

1. Premium homepage
2. Product/how-it-works experience
3. Pricing page/section
4. Login page
5. Download/product access experience where supported
6. Founder/story content
7. Comparison content
8. Technical/product presentation
9. Privacy information
10. Functional contact experience
11. Responsive navigation
12. SEO/social metadata
13. Original visual assets
14. Working interactions
15. Local validation

Do not deploy.

Do all implementation and verification locally.

---

# 1. FIRST: FULL REPOSITORY AUDIT

Before editing anything, inspect:

- `index.html`
- `styles.css`
- `script.js`
- `readme.md`
- `.claude/`
- `content/`
- `presentation/`
- `public/`
- `server.py`
- all assets
- all API/contact/auth-related implementation
- package configuration if present
- any generated/build files
- routing structure if present

Also inspect whether there is an existing backend/auth implementation outside this directory.

Do not discard working functionality.

Do not replace existing backend behavior merely to simplify frontend work.

Identify:

- existing routes
- existing APIs
- auth endpoints
- contact endpoint
- download endpoints
- database/API dependencies
- environment requirements
- currently broken links
- placeholder content
- fake statistics
- unsupported product claims

Create an internal implementation map before modifying files.

---

# 2. HOMEPAGE IS THE PRIMARY PRODUCT EXPERIENCE

The homepage should remain the main A-Anie product story.

Core positioning:

> It doesn't simply transcribe what you said.  
> It writes what you meant.

Core mental model:

Traditional dictation:

`SPEAK → TRANSCRIBE → TEXT`

A-Anie:

`SPEAK → UNDERSTAND → EDIT → WRITE`

The difference must be visually obvious within the first few seconds.

Preserve the existing warm editorial identity described in the README.

Do not replace the visual identity with a generic SaaS template.

---

# 3. HOMEPAGE STRUCTURE

Build the homepage approximately in this order:

## Navigation

A-Anie

- Product
- How it works
- Languages
- Pricing
- Docs
- Changelog
- Story

Primary CTA:

`Download`

Secondary auth action where appropriate:

`Log in`

Mobile navigation must use an actual accessible mobile menu.

Do not merely hide links on mobile.

---

## Hero

Include:

- product/category label
- large editorial headline
- supporting sentence
- primary CTA
- secondary "See how it works" CTA
- supported platforms
- interactive voice → intent → text demonstration

The product demo must be the main visual focus.

Build it as a real interaction rather than a decorative static card.

---

# 4. PRODUCT DEMONSTRATION

Create an animated product simulation.

Flow:

RAW SPEECH

Example:

"uhh yeah so I think maybe Tuesday would uh—
no wait, Wednesday works better..."

Then show processing:

A-ANIE UNDERSTANDS

- filler removed
- self-correction resolved
- repetition removed
- tone preserved

Then:

A-ANIE WRITES

"Wednesday works better."

Build:

- waveform animation
- progressive text appearance
- transformation states
- subtle cursor movement
- active processing indicator
- visual transition between states

Respect `prefers-reduced-motion`.

---

# 5. INTERACTIVE PRODUCT SECTIONS

The homepage must demonstrate the product instead of only explaining it.

Implement interactive examples for:

## Tone

Input:

"uh yeah that seems fine"

Controls:

- Formal
- Casual
- Very casual

Each should visibly transform the output.

## Language

Controls:

- English
- Hindi
- Hinglish
- Marathi
- Tamil
- Bengali
- Telugu

Show realistic example transformations.

Do not fabricate unsupported capabilities.

Only show languages supported by repository evidence.

## Personal Dictionary

Demonstrate preservation of terms such as:

- Kishangarh
- Dohdiya
- A-Anie

The purpose is to show that personal vocabulary is remembered rather than "corrected" incorrectly.

---

# 6. PRICING PAGE

Add a dedicated pricing route/page.

Preferred route:

`/pricing`

Also provide an appropriate homepage pricing section linking to it.

IMPORTANT:

Do not invent pricing.

Inspect the repository for actual pricing, billing, product plans, Stripe configuration, backend billing information, or pricing copy.

If there is verified pricing, implement it accurately.

If pricing is incomplete or unavailable:

Use an intentional early-product presentation.

For example:

- Free access / early access where verified
- No card / no trial / no email gate only if the repository confirms those claims
- "Pricing coming soon" where information genuinely does not exist

Do not create fake Pro / Team / Enterprise plans.

Do not invent prices.

Do not invent feature quotas.

Do not invent billing functionality.

The pricing page should still look complete and intentional even when exact commercial details are unavailable.

Include:

- pricing philosophy
- feature availability based on evidence
- platform support based on evidence
- FAQ
- CTA
- login/download path where applicable

If billing infrastructure exists, connect to it instead of mocking it.

---

# 7. LOGIN PAGE

Add a dedicated login experience.

Preferred route:

`/login`

First determine whether authentication already exists.

Inspect:

- API routes
- auth controllers
- sessions
- JWT handling
- cookies
- password hashing
- Prisma schema
- frontend auth utilities
- environment variables

If authentication already exists:

WIRE THE LOGIN PAGE TO THE REAL AUTH FLOW.

Do not create fake authentication.

Handle:

- loading
- invalid credentials
- server errors
- successful authentication
- logged-in redirect
- logged-out state

Use accessible labels and error messages.

Do not expose secrets.

Do not put credentials in frontend source.

If authentication does NOT exist, do not invent a fake auth backend.

Instead create a truthful login experience clearly connected to the actual available product/auth state, or an appropriate "account access coming soon" state, depending on repository evidence.

Do not implement imaginary account functionality just to make the page look complete.

---

# 8. AUTH NAVIGATION BEHAVIOR

Navigation should understand the authentication state if the repository provides authentication.

When logged out:

- Log in
- Download / Get started

When logged in:

- Account / Dashboard where supported
- Download / Open app where supported
- Log out

Do not create dashboard routes that do not exist.

---

# 9. FOUNDER / STORY PAGE

Create the founder/product-origin story described in `readme.md`.

Use the Kishangarh origin story only to the extent supported by repository content.

Suggested route:

`/story`

The story should explain:

- the original problem
- typing friction
- Indian English
- Hinglish
- names/pronunciation
- building alone
- technical challenges
- product philosophy
- what "writes what you meant" means
- what comes next

Do not fabricate dates, users, investors, funding, launch numbers, or achievements.

---

# 10. HOW IT WORKS

Create a proper `/how-it-works` experience or equivalent routed section if the architecture permits.

Explain:

1. Speak
2. Understand
3. Clean
4. Personalize
5. Write

Each stage should have an original visual treatment.

Prefer product UI and SVG over generic illustrations.

---

# 11. COMPARISON

Create a polished comparison section/page.

Compare A-Anie against:

- Wispr Flow
- Built-in OS dictation

Only publish competitor facts that can be verified.

For unavailable values, explicitly mark them as unavailable rather than guessing.

Comparison dimensions may include:

- Price
- Voice-to-text
- Intent-aware cleanup
- Filler removal
- Self-correction
- Repetition cleanup
- Indian English
- Hinglish
- Regional languages
- Personal dictionary
- Tone control
- System-level insertion
- Platforms
- Offline support
- Privacy/data handling

The README explicitly prohibits invented competitor specifications.

Research current competitor information when required and cite sources in the content where appropriate.

---

# 12. PRIVACY

Create a visible privacy/data explanation.

Preserve only verified repository claims.

Current specification says to accurately represent:

- audio transcription/disposal behavior
- transcript retention
- deletion behavior
- absence of unsupported certifications

Do not invent:

- SOC 2
- ISO 27001
- HIPAA
- GDPR certification
- security guarantees

---

# 13. CONTACT

Preserve the real contact flow.

The README specifies:

`POST /api/v1/contact`

Verify the backend implementation and its exact contract.

The frontend must correctly handle:

- name
- email
- topic
- message
- loading
- success
- validation
- server failure

Do not replace the real API with a fake frontend-only success message.

---

# 14. VISUAL SYSTEM

Preserve and refine:

- warm cream background
- near-black text
- lavender accent
- subtle saffron/amber accent
- editorial serif
- clean sans-serif UI type
- monospace technical metadata

The target is:

warm + intelligent + technical + Indian + premium

Avoid:

- generic AI blobs
- excessive gradients
- rainbow palettes
- stock illustrations
- giant glass cards
- cliché neural graphics
- excessive rounded containers
- decorative effects without product purpose

Use layout rhythm.

Mix:

- editorial full-width sections
- dense product UI
- quiet whitespace
- technical detail

Do not make every section look like a card grid.

---

# 15. SVG ASSET SYSTEM

Create original, cohesive SVG artwork.

Expected assets:

`public/illustrations/hero.svg`
`public/illustrations/intent.svg`
`public/illustrations/personalization.svg`
`public/illustrations/languages.svg`
`public/illustrations/injection.svg`
`public/illustrations/founder.svg`
`public/illustrations/privacy.svg`
`public/illustrations/architecture.svg`
`public/illustrations/cta.svg`

The visual grammar must be consistent.

Prefer:

- waveform
- cursor
- text fragments
- transformation arrows
- speech marks
- keyboard/input layers
- language switching
- dictionary concepts
- signal → meaning → text

---

# 16. OG IMAGE

Create:

`public/og-image.png`

Target:

`1200 × 630`

Use:

A-Anie

"It writes what you meant."

plus a refined waveform → text composition.

Update metadata to point to the generated asset.

Also implement:

- title
- description
- canonical
- Open Graph
- Twitter cards
- favicon
- structured metadata where appropriate
- semantic headings
- robots
- sitemap where architecture supports it

---

# 17. CONTENT FILES

Create/update:

`content/solo-developer-journey.md`

`content/comparison.md`

`presentation/a-anie-product-vision.md`

Do not generate invented business facts.

Clearly separate:

- verified current facts
- product positioning
- proposed/future concepts

---

# 18. PRESENTATION

Create the premium product/collaborator presentation described by the README.

Use approximately:

01 A-Anie
02 The problem
03 The insight
04 The product
05 Product experience
06 Differentiation
07 Indian-language opportunity
08 Target users
09 Product roadmap
10 Go-to-market
11 Business model
12 Why now
13 Founder story
14 Vision

Do not invent traction.

For business model or roadmap information that is not established, explicitly label it as proposed.

---

# 19. REMOVE PLACEHOLDER EXPERIENCE

Search the entire repository for:

`PLACEHOLDER`

Also search for:

- fake testimonials
- fake statistics
- fake customer logos
- fake user counts
- fake release metrics
- fake links
- `href="#"`

Do not expose placeholder text publicly.

Where evidence is unavailable:

- remove the claim
- use "coming soon"
- use an honest early-stage statement
- or omit the section

Do not manufacture credibility.

---

# 20. FIX FOOTER / CTA DESTINATIONS

The existing specification warns that:

- footer links currently contain placeholder `#`
- download CTA currently uses `href="#"`

Fix every such destination.

Every link should be:

- a real route
- a real external destination
- a real download destination
- or a deliberate disabled/coming-soon state

No dead links.

---

# 21. PERFORMANCE

Prefer:

- CSS
- SVG
- lightweight JavaScript
- existing dependencies
- lazy loading where appropriate

Do not introduce a large animation framework simply for decorative animation.

No unnecessary analytics.

No unnecessary third-party scripts.

Animations should remain cheap and composited where practical.

---

# 22. ACCESSIBILITY

Verify:

- semantic HTML
- keyboard navigation
- visible focus
- ARIA where necessary
- accessible forms
- mobile navigation
- reduced-motion support
- sufficient contrast
- screen-reader compatibility

Do not sacrifice accessibility for visual polish.

---

# 23. RESPONSIVE BREAKPOINTS

Explicitly test:

- 390px
- 768px
- 1024px
- 1440px
- 1920px+

Check:

- navigation
- hero
- typography
- demo animation
- comparison table
- forms
- CTA
- footer
- mobile menu

Requirements:

No horizontal overflow.

No clipped animation.

No broken typography.

No giant empty areas.

No unusable tables.

---

# 24. LOCAL EXECUTION

Actually run the application.

Determine the correct local command from the repository.

Examples only where applicable:

`python server.py`

or the project's existing package scripts.

Do not assume.

Test all important routes.

At minimum verify:

`/`
`/pricing`
`/login`

and any implemented:

`/how-it-works`
`/story`

Also verify contact functionality.

Check browser console errors.

Check network failures.

Check broken links.

Check responsive behavior.

---

# 25. FINAL QA

Before declaring completion:

1. Does the homepage communicate the product in 10 seconds?
2. Is the voice → intent → text transformation unmistakable?
3. Does pricing reflect only verified product information?
4. Does login use real authentication where authentication exists?
5. Are fake claims removed?
6. Are placeholder links removed?
7. Does contact still hit the actual API?
8. Is the site polished at 390px?
9. Is the technical credibility section factual?
10. Is privacy wording factual?
11. Are animations accessible?
12. Are there console errors?
13. Are all major routes working?
14. Are metadata/OG assets connected?
15. Does the site feel like a real product rather than a template?

If something is visually weak or technically incomplete, fix it before stopping.

---

# 26. COMPLETION REPORT

When finished, report exactly:

## Changed

Major implementation changes.

## Created

All new files.

## Modified

All modified files.

## Routes

List all verified routes.

## APIs

List APIs inspected and verified.

## Authentication

Explain whether existing authentication was found and whether `/login` was connected to it.

## Pricing

Explain whether pricing was verified, unavailable, or implemented from existing repository evidence.

## Local Run

Exact command used.

## Local URL

Exact URL.

## Validation

Responsive breakpoints tested, accessibility checks, console/network checks, and link checks.

## Known Limitations

Only factual unresolved issues.

## Deployment Configuration

Anything that must be configured before deployment.

Do not deploy automatically.