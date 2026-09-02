// POST /api/auth/login
//
// Body: { email: string, code?: string }
//
// Current state: NOT DEPLOYED. The login UI on /login.html is a
// placeholder; the real product is a desktop app. The wispr-style
// two-step (email + OTP) is preserved as a shape for when the
// backend actually ships. The 501 response uses the same JSON
// shape the front-end expects.
//
// When the real path ships:
//   1. If the request contains a 6-digit code, verify it against
//      the stored OTP for the email. On match, issue a session
//      token and return {ok: true, session_token, expires_at}.
//   2. If the request contains only an email, generate a 6-digit
//      OTP, store it server-side with a 5–10 minute TTL, email
//      it to the user, and return {ok: true, expires_in: 600}.
//   3. On any failure: return 401 with a generic "code is
//      incorrect or expired" message; do not distinguish "wrong
//      code" from "no code" to avoid email enumeration timing
//      attacks.
export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ ok: false, error: 'Method not allowed' });
  }

  res.setHeader('Cache-Control', 'no-store');

  const body = req.body || {};
  const email = (body.email || '').trim();
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return res.status(400).json({ ok: false, error: 'Please enter a valid email.' });
  }

  return res.status(501).json({
    ok: false,
    error: 'Login is not enabled yet. The form is wired up so the UX is real; the email-delivery and session steps are not deployed. Email sachin@a-anie.example if you would like to be notified when it is.'
  });
}
