#!/usr/bin/env node
// A-Anie API smoke test.
// Hits each backend endpoint, asserts expected status codes.
// Defaults to production because api/*.js are Vercel serverless functions
// that don't run on a plain http.server.
//
// Usage:
//   npm run smoke:api                       # production
//   API_BASE_URL=http://localhost:3000 npm run smoke:api
//
// Exits 0 on success, 1 on any failure.

const API_BASE_URL = process.env.API_BASE_URL || 'https://aanie-frontend.vercel.app';

const ENDPOINTS = [
  {
    name: 'contact.valid',
    method: 'POST',
    path: '/api/v1/contact',
    headers: { 'content-type': 'application/json' },
    body: {
      name: 'Test User',
      email: 'test@example.com',
      topic: 'general',
      message: 'This is a test message that is long enough to pass validation.',
    },
    expectStatus: 200,
  },
  {
    name: 'contact.missing_email',
    method: 'POST',
    path: '/api/v1/contact',
    headers: { 'content-type': 'application/json' },
    body: { name: 'Test', topic: 'general', message: 'long enough message body here' },
    expectStatus: 400,
  },
  {
    name: 'contact.short_message',
    method: 'POST',
    path: '/api/v1/contact',
    headers: { 'content-type': 'application/json' },
    body: { name: 'Test', email: 't@example.com', topic: 'general', message: 'short' },
    expectStatus: 400,
  },
  {
    name: 'contact.wrong_method',
    method: 'GET',
    path: '/api/v1/contact',
    expectStatus: 405,
  },
  {
    name: 'contact.not_found',
    method: 'POST',
    path: '/api/v1/contact/nonexistent',
    headers: { 'content-type': 'application/json' },
    body: {},
    expectStatus: 404,
  },
];

let passCount = 0;
let failCount = 0;
const failures = [];

console.log(`API base: ${API_BASE_URL}\n`);

for (const ep of ENDPOINTS) {
  const url = `${API_BASE_URL}${ep.path}`;
  const opts = { method: ep.method, headers: ep.headers || {} };
  if (ep.body !== undefined) opts.body = JSON.stringify(ep.body);

  let actual;
  let error;
  try {
    const resp = await fetch(url, opts);
    actual = resp.status;
  } catch (e) {
    actual = 'ERR';
    error = e.message;
  }

  const ok = actual === ep.expectStatus;
  const tag = ok ? '✓' : '✗';
  console.log(`${tag} ${ep.name.padEnd(28)} ${ep.method.padEnd(4)} ${ep.path.padEnd(28)} → ${actual} (expected ${ep.expectStatus})`);

  if (ok) {
    passCount++;
  } else {
    failCount++;
    failures.push({ name: ep.name, actual, expected: ep.expectStatus, error });
  }
}

console.log('');
console.log(`Checks: ${passCount} passed, ${failCount} failed`);
if (failures.length > 0) {
  console.log('\nFailures:');
  for (const f of failures) {
    console.log(`  ${f.name}: got ${f.actual}, expected ${f.expected}${f.error ? ' (' + f.error + ')' : ''}`);
  }
}

process.exit(failCount === 0 ? 0 : 1);
