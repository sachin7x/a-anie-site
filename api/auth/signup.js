// POST /api/auth/signup
//
// Body: { email: string }
//
// Current state: NOT DEPLOYED. The signup UI on /signup.html is a
// clone of the wispr webflow two-step UX (email + OTP) ported to
// A-Anie's design system. The server-side email + OTP delivery is
// not built. The UI is shipped so the user-facing flow is real, and
// this stub returns 501 with the JSON shape the front-end expects.
//
// When the real signup path ships:
//   1. Validate the email format (already done in the front-end).
//   2. Generate a 6-digit OTP, store it server-side keyed by email
//      with a short TTL (5–10 minutes).
//   3. Email the code to the user. For a solo-built product, the
//      simplest reliable path is Resend + a verified sending domain.
//   4. Return {ok: true, expires_in: 600}.
//
// The 501 path is intentional: better to have the form work end-to-end
// visually than to leave the URL as a 404.
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

  // Honest not-deployed response. The front-end shows the verbatim
  // error string under the form so users know what to do.
  return res.status(501).json({
    ok: false,
    error: 'Signup is not enabled yet. The form is wired up so the UX is real; the email-delivery step is not deployed. Email sachin@a-anie.example if you would like to be notified when it is.'
  });
}
