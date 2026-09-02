// POST /api/auth/verify-otp
//
// Body: { email: string, code: string (6 digits) }
//
// Current state: NOT DEPLOYED. Pair to /api/auth/signup.js. Same
// pattern: the UI is shipped, the server side is not. The 501 response
// uses the same JSON shape the front-end expects so the UX of "try
// again later" is honest.
//
// When the real path ships:
//   1. Look up the OTP for the email; reject if missing or expired.
//   2. Constant-time compare the submitted code against the stored one.
//   3. On match: create the user account (or log the existing one in),
//      issue a session token, and return {ok: true, session_token, ...}.
//   4. On mismatch: return 401 with a generic "code is incorrect or
//      expired" message — do not distinguish "wrong code" from "no
//      code" to avoid email enumeration timing attacks.
export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ ok: false, error: 'Method not allowed' });
  }

  res.setHeader('Cache-Control', 'no-store');

  const body = req.body || {};
  const email = (body.email || '').trim();
  const code = (body.code || '').toString().trim();
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return res.status(400).json({ ok: false, error: 'Invalid email.' });
  }
  if (!/^[0-9]{6}$/.test(code)) {
    return res.status(400).json({ ok: false, error: 'Code must be six digits.' });
  }

  return res.status(501).json({
    ok: false,
    error: 'Code verification is not enabled yet. Email sachin@a-anie.example if you would like to be notified when signup is live.'
  });
}
