#!/usr/bin/env node
// A-Anie frontend smoke test.
// Loads each page, asserts Bootstrap loaded (SRI didn't fail),
// the navbar is structurally present and in its expanded row layout,
// and primary CTAs render as Bootstrap buttons.
//
// Usage:
//   npm run smoke         # smoke localhost (default; safe to spam)
//   npm run smoke:prod    # smoke production (opt-in)
//
// Exits 0 on success, 1 on any failure.

import { chromium } from 'playwright';

const BASE_URL = process.env.BASE_URL || 'http://localhost:8000';
const PAGES = [
  { path: '/', name: 'index', requireFullNav: true },
  { path: '/story', name: 'story', requireFullNav: true },
  { path: '/pricing', name: 'pricing', requireFullNav: true },
  { path: '/how-it-works', name: 'how-it-works', requireFullNav: true },
  { path: '/login', name: 'login', requireFullNav: false },
  { path: '/data-controls', name: 'data-controls', requireFullNav: true },
  { path: '/terms', name: 'terms', requireFullNav: false },
];

// What "Bootstrap actually loaded" looks like, in computed style.
// .navbar-expand-lg at >=992px viewport keeps .navbar-collapse always visible
// and the .navbar-nav in its horizontal flex row. If Bootstrap never applied,
// .navbar-nav falls back to <ul> defaults (block, vertical, padded).
const DESKTOP_VIEWPORT = { width: 1280, height: 800 };

const results = [];
let browser;

try {
  browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: DESKTOP_VIEWPORT });
  const page = await ctx.newPage();

  for (const { path, name, requireFullNav } of PAGES) {
    const url = `${BASE_URL}${path}`;
    const checks = [];
    let pageOk = true;
    const fail = (msg) => { pageOk = false; checks.push({ ok: false, msg }); };
    const pass = (msg) => checks.push({ ok: true, msg });

    try {
      const resp = await page.goto(url, { waitUntil: 'networkidle', timeout: 30_000 });
      if (!resp || !resp.ok()) {
        fail(`HTTP ${resp ? resp.status() : 'no response'} loading ${url}`);
        results.push({ name, url, ok: false, checks });
        continue;
      }
      pass(`HTTP ${resp.status()} ${url}`);

      // 1. Bootstrap stylesheet must have applied. The tell: .navbar has its
      //    Bootstrap-computed padding (not the browser-default 0). And .btn
      //    has Bootstrap's button padding (8px 16px on .btn).
      const hasNavbar = await page.locator('.navbar').count() > 0;
      if (!hasNavbar) {
        if (requireFullNav) {
          fail('no .navbar element found — expected on this page');
        } else {
          pass('no .navbar (intentional on this page)');
        }
      } else {
        const navPadTop = await page.$eval('.navbar', el => getComputedStyle(el).paddingTop);

        // Bootstrap .navbar padding-top is 8px (--bs-navbar-padding-y: 0.5rem).
        // Browser default for <nav> is 0. Threshold 6 sits between, with margin
        // for any custom override (we set 8px in styles.css).
        if (parseFloat(navPadTop) < 6) {
          fail(`.navbar padding-top is ${navPadTop} — Bootstrap CSS likely did not load`);
        } else {
          pass(`.navbar padding-top = ${navPadTop} (Bootstrap applied)`);
        }

        // Dark navbar background applied (bg-dark = ~#0F0F0F from our token).
        const navBg = await page.$eval('.navbar', el => getComputedStyle(el).backgroundColor);
        const m = navBg.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
        if (m) {
          const [r, g, b] = [parseInt(m[1]), parseInt(m[2]), parseInt(m[3])];
          const isDark = (r + g + b) / 3 < 100;
          if (!isDark) {
            fail(`.navbar background is ${navBg} — bg-dark likely not applied`);
          } else {
            pass(`.navbar background = ${navBg} (dark theme applied)`);
          }
        } else {
          fail(`.navbar background unparseable: ${navBg}`);
        }
      }

      // 2. Bootstrap .btn is in the DOM with Bootstrap-computed styles.
      //    We check even on pages without a navbar, because buttons appear in
      //    login.html, terms.html (TOC links styled as buttons?), etc.
      const btnCount = await page.locator('.btn').count();
      if (btnCount > 0) {
        const btnPadX = await page.locator('.btn').first().evaluate(el => getComputedStyle(el).paddingLeft);
        const btnRadius = await page.locator('.btn').first().evaluate(el => getComputedStyle(el).borderRadius);
        if (parseFloat(btnPadX) < 8) {
          fail(`.btn padding-left is ${btnPadX} — Bootstrap CSS likely did not load`);
        } else {
          pass(`.btn padding-left = ${btnPadX} (Bootstrap applied)`);
        }
        if (btnRadius === '0px') {
          fail(`.btn border-radius is 0 — Bootstrap CSS likely did not load`);
        } else {
          pass(`.btn border-radius = ${btnRadius} (Bootstrap applied)`);
        }
      } else if (requireFullNav) {
        fail('no .btn found — expected at least one on this page');
      } else {
        pass('no .btn on this page (OK)');
      }

      // 3. Full-nav checks (toggler, link count, row layout) only when required.
      if (requireFullNav) {
        const togglerCount = await page.locator('.navbar-toggler').count();
        if (togglerCount === 0) {
          fail('.navbar-toggler not found');
        } else {
          pass(`.navbar-toggler present (${togglerCount})`);
        }

        const navLinkCount = await page.locator('.navbar .nav-link, .navbar .btn').count();
        if (navLinkCount < 2) {
          fail(`expected >=2 nav links/buttons, found ${navLinkCount}`);
        } else {
          pass(`${navLinkCount} nav links/buttons present`);
        }

        // At desktop viewport, .navbar-nav should be in a flex row, not stacked.
        const linkBoxes = await page.locator('.navbar .nav-link').evaluateAll(els =>
          els.slice(0, 3).map(el => {
            const r = el.getBoundingClientRect();
            return { top: Math.round(r.top), left: Math.round(r.left), w: Math.round(r.width) };
          })
        );
        if (linkBoxes.length >= 2) {
          const firstTop = linkBoxes[0].top;
          const allSameRow = linkBoxes.every(b => Math.abs(b.top - firstTop) < 4);
          if (!allSameRow) {
            fail(`nav links appear vertically stacked (tops: ${linkBoxes.map(b => b.top).join(', ')}) — Bootstrap collapse/layout not working`);
          } else {
            pass(`nav links on same row (top ≈ ${firstTop}px)`);
          }
        }
      }
    } catch (e) {
      fail(`exception: ${e.message}`);
    }

    results.push({ name, url, ok: pageOk, checks });
  }

  await browser.close();
} catch (e) {
  console.error(`fatal: ${e.message}`);
  if (browser) await browser.close();
  process.exit(2);
}

// Report
console.log('');
let passCount = 0, failCount = 0;
for (const r of results) {
  const tag = r.ok ? '✓' : '✗';
  console.log(`${tag} ${r.name.padEnd(16)} ${r.url}`);
  for (const c of r.checks) {
    const sym = c.ok ? '  ✓' : '  ✗';
    console.log(`${sym} ${c.msg}`);
    c.ok ? passCount++ : failCount++;
  }
  console.log('');
}

const totalPages = results.length;
const okPages = results.filter(r => r.ok).length;
console.log(`Pages: ${okPages}/${totalPages} OK | Checks: ${passCount} passed, ${failCount} failed`);

process.exit(failCount === 0 ? 0 : 1);
