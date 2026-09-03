// POST /api/transcribe
//
// Receives a multipart/form-data payload with an `audio` field (a
// webm/wav blob captured from the browser MediaRecorder).
//
// Current state: NOT DEPLOYED. The desktop app is the real product;
// the web demo is a research surface. This stub returns 501 with the
// same JSON shape the wispr client code expects (`{ok, text}` or
// `{ok:false, error}`) so the front-end can handle it the same way it
// would handle a transient backend failure.
//
// What the six-phase audio-processing-failure contract says about
// this endpoint's current state (see
// harness/docs/ANNIE_AUDIO_FAILURE_CONTRACT.md for the full contract):
//   - Phase 0 (Capture and finalize) is implemented client-side by
//     public/app.html via getUserMedia + MediaRecorder.
//   - Phases 1-5 (Promote, Recognize, Clean up, Commit, Deliver) are
//     not implemented in this web surface. The /app page does not
//     send audio to any transcription service; it surfaces this 501
//     honestly so the user knows what is and is not attached.
//   - No aidictation cloud STT, no Groq / OpenAI / Ollama call, no
//     Supabase round-trip, no auth, no billing is involved.
//
// When the server-side transcription path is built, replace the body
// of this handler. The function signature, content-type handling, and
// response shape are all already correct for the front-end to call.
export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ ok: false, error: 'Method not allowed' });
  }

  // CORS — same as the wispr pattern. The site is on Vercel; allow
  // the same origin and the preview deploys.
  res.setHeader('Cache-Control', 'no-store');

  // Minimal validation: confirm there is an `audio` field. Vercel's
  // body parser populates req.body and req.files for multipart, but
  // we only check that the content-type is what we expect.
  const ct = (req.headers['content-type'] || '').toLowerCase();
  if (!ct.startsWith('multipart/form-data') && !ct.startsWith('application/octet-stream')) {
    return res.status(400).json({
      ok: false,
      error: 'Expected multipart/form-data with an audio field.'
    });
  }

  // Honest not-deployed response. The front-end shows the verbatim
  // error string in the textbox so users know what happened.
  return res.status(501).json({
    ok: false,
    error: 'Transcription endpoint is not deployed. The /app web surface only provides phase 0 (browser capture); phases 1-5 (Promote, Recognize, Clean up, Commit, Deliver) are not built here. No audio is sent to a transcription service by this stub. Use the A-Anie desktop app for real transcription; the web demo on this page is for mic-permission and waveform testing only. See harness/docs/ANNIE_AUDIO_FAILURE_CONTRACT.md for the full six-phase model.'
  });
}
