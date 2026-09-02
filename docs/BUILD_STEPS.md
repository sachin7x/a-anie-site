# A-Anie Site — Build & Deploy Runbook

> How to compile the marketing site from source and ship a preview.
> Last updated 2026-09-03.

## What "compile from web" means for this site

A-Anie's marketing site is **static HTML + CSS + JS**. There is no
build step. "Compile from web" = regenerate the `public/` directory
and the serverless API stubs so that what you see locally matches
what Vercel serves. The only transformations are:

- Bootstrap 5 is loaded from the pinned CDN with SRI hashes already
  baked into `<head>`. Do not change them; do not pin to a new
  version without re-computing the hash.
- Three serverless API handlers (`api/transcribe.js`,
  `api/auth/signup.js`, `api/auth/verify-otp.js`) ship as Node.js
  modules and are deployed by Vercel as functions automatically.
- The wispr `/demo/` mirror under `public/demo/` is a static copy of
  byte-identical bundles. Do not regenerate it from source — the
  bundles on disk are the source of truth.

## Prerequisites

- Node 18+ (Vercel uses 18.x and 20.x).
- Vercel CLI: `npm i -g vercel` (optional — the dashboard works too).
- A Vercel account with access to the `a-anie-site` project.

## Directory layout

```
public/                 # Static site root
  index.html            # Marketing landing
  how-it-works.html
  pricing.html
  story.html
  data-controls.html
  security              # directory, served as /security/
  terms.html
  accessibility.html
  careers.html
  support.html
  changelog.html
  contact.html
  signup.html
  login.html
  demo/                 # unmodified wispr mirror (research artifact)
  styles.css
  script.js
  well-known/
    security.txt
api/                    # Vercel serverless functions
  contact.js            # 501 stub
  transcribe.js         # 501 stub (mic demo backend)
  auth/
    signup.js           # 501 stub
    verify-otp.js       # 501 stub
docs/                   # Documentation that ships with the repo
  WISPR_TO_ANNIE_HOW_IT_WORKS.md
  BUILD_STEPS.md        # this file
vercel.json             # rewrites + cleanUrls
```

## How to run locally

```bash
cd /Users/sachin/Pictures/ANNIE
npx vercel dev
# or, for static-only:
npx http-server public -p 3000
```

The Vercel dev server picks up the `api/` functions automatically
and serves them at the rewritten paths
(`/api/v1/contact` → `/api/contact`, etc.).

## How to ship a preview

```bash
cd /Users/sachin/Pictures/ANNIE
git add -A
git commit -m "..."
git push origin <branch>
vercel deploy --yes
```

Or via the dashboard: connect the repo, push to a non-`main` branch,
Vercel builds a preview URL automatically.

The `vercel.json` is the authoritative source for routes:

```json
{
  "cleanUrls": true,
  "rewrites": [
    { "source": "/api/v1/:path*", "destination": "/api/:path*" }
  ]
}
```

## How to ship to production

The production URL is `https://aanie-frontend.vercel.app/`. The user
has stated explicitly: **"This is the main URL, this should never be
down."** Treat the production deploy as load-bearing.

```bash
git checkout main
git pull --ff-only
git merge --no-ff <preview-branch>
git push origin main
# Vercel auto-deploys main
```

Before pushing to main:

1. Run the smoke test (see below).
2. Verify the `vercel.json` rewrites still match the live API surface.
3. Confirm the Bootstrap SRI hashes are unchanged
   (`grep -n 'integrity' public/index.html`).

## Smoke test (13 pages)

Run before any merge to main, or after any change that touches
`public/`:

```bash
for p in index how-it-works pricing story data-controls terms \
         security accessibility careers support changelog contact signup login; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "https://aanie-frontend.vercel.app/$p.html" || echo "ERR")
  echo "$p: $code"
done
# Also:
curl -s -o /dev/null -w "/security: %{http_code}\n" "https://aanie-frontend.vercel.app/security"
curl -s -o /dev/null -w "/api/v1/contact: %{http_code}\n" -X POST "https://aanie-frontend.vercel.app/api/v1/contact" -d '{}' -H "Content-Type: application/json"
curl -s -o /dev/null -w "/api/transcribe: %{http_code}\n" -X POST "https://aanie-frontend.vercel.app/api/transcribe" -d '{}'
curl -s -o /dev/null -w "/api/auth/signup: %{http_code}\n" -X POST "https://aanie-frontend.vercel.app/api/auth/signup" -d '{"email":"x@y.z"}'
curl -s -o /dev/null -w "/api/auth/verify-otp: %{http_code}\n" -X POST "https://aanie-frontend.vercel.app/api/auth/verify-otp" -d '{"email":"x@y.z","code":"123456"}'
```

Expected: all 200 for pages (some 200-with-content), 405/501 for the
API stubs (405 for wrong method, 501 for the not-deployed path).

## Verifying preview-deploy API stubs (Vercel SSO)

Vercel Deployment Protection intercepts every request to a preview
deploy with a 401 "Protected deployment" response before it ever
reaches the function. The front-end on `/app` already detects this
401 and surfaces it honestly ("Preview is behind Vercel SSO"). To
verify the actual stub response (e.g. that `/api/auth/signup` returns
501 with the correct body), bypass the SSO gate with the Vercel CLI:

```bash
# from the repo root, with `vercel link` already done:
vercel curl "<preview-url>/api/auth/signup" \
  -X POST -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'
# → {"ok":false,"error":"Signup is not enabled yet..."}
```

`vercel curl` injects the `x-vercel-protection-bypass` header
automatically. The same trick works for every `/api/*` endpoint on
any preview URL. Without the bypass, public traffic sees 401 — that
is the deployment-protection layer, not a stub bug.

The production URL is **not** behind SSO (it is the verified domain
`aanie-frontend.vercel.app`); its API stubs are reachable normally.

## How to update the Bootstrap SRI hash (do not, unless forced)

The hashes are pinned to a specific Bootstrap 5.3.3 build. If you
must upgrade:

```bash
curl -s https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css | \
  openssl dgst -sha384 -binary | openssl base64 -A
```

Paste the result into every `integrity="sha384-..."` in every HTML
file in `public/`. There are 13 files; use a single sed pass.

## How to add a new page

1. Copy `public/careers.html` as a template — it has the canonical
   nav, footer, Bootstrap CDN link, and SRI hash already in place.
2. Add the new page to the navbar `<ul class="navbar-nav">` of every
   other page (the 13 listed above).
3. Add the new page to the footer columns of every other page.
4. Add the path to the smoke-test loop in this file.
5. Commit. Push. Vercel preview URL is the deliverable.

## What NOT to do

- Do not change the Bootstrap version or SRI hash without
  re-verifying all 13 pages.
- Do not remove the wispr `/demo/` mirror — it is a research
  artifact and a reference for the inlined web-demo on the
  landing page.
- Do not replace `styles.css` with anything that defines `.nav` or
  `.btn` rules — those override Bootstrap and break the navbar.
- Do not push to main without running the smoke test.
- Do not claim features that are not in product code (no SOC 2,
  no 99.9% SLA, no latency number, no accuracy number, no
  Windows/Linux/iOS/Android support).
