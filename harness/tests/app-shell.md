# App Shell Tests — `/app` and the wispr-style dictation entry

> The `/app` page in `public/app.html` is the in-browser dictation entry. It is a real getUserMedia + AnalyserNode + Space-to-record surface that POSTs recorded audio to `/api/transcribe` (a 501 stub). The page's response handler has four branches, each of which must surface a verbatim, honest message — never a fake transcript.

## The four branches

The handler in `public/app.html` (the `sendForTranscription()` function) handles:

| Branch | Trigger | Expected behaviour | Codifies |
|---|---|---|---|
| 501 / `{error:"not_implemented"}` | The real stub response (only reachable via `vercel curl`) | Render the backend error verbatim in the transcript box | D001, F004 |
| 200 with `{text:"..."}` | A real transcription success | Render the returned text in the transcript box (currently unreachable — no real backend) | D001 |
| 401 (Vercel SSO) | Public traffic on the preview | Render "Preview is behind Vercel SSO (401). The transcription endpoint is not deployed; the page just hit the deployment-protection layer first." | D003, F008 |
| Network error / other status | Any other failure | Render the status code and a fallback "Network error" string with the contact email | D001 |

## T10. The 501 branch is reachable via `vercel curl` and surfaces a verbatim backend error

- **Expected:** The HTML page contains a branch that reads `out.status === 501 || (out.j && out.j.error === 'not_implemented')` and renders the backend error string in the transcript box.
- **Codifies:** D001, F004, F008.
- **Static check:**
  ```bash
  grep -c "not_implemented\|Backend not deployed" public/app.html
  # expected: ≥ 2 (one in the handler, one in the user-facing message)
  ```
- **Pass condition:** the grep returns ≥ 2 matches; the strings appear in the IIFE that wires the response.

## T11. The 401 branch is present and contains the SSO message

- **Expected:** The HTML page contains a branch that reads `out.status === 401` and renders a string mentioning "Vercel SSO" and the contact email.
- **Codifies:** D003, F008.
- **Static check:**
  ```bash
  grep -c "Vercel SSO\|deployment-protection" public/app.html
  # expected: ≥ 2
  ```

## T12. The 200-with-`{text}` branch is present and is the only "success" path

- **Expected:** A branch that reads `out.j && out.j.text` and renders the returned text. There must be no other "success" path that fabricates a transcript.
- **Codifies:** D001 (no fake transcript).
- **Static check:**
  ```bash
  grep -c "out.j.text\|j.text" public/app.html
  # expected: ≥ 1
  grep -c "fake\|sample.*transcript\|placeholder.*text" public/app.html
  # expected: 0
  ```

## T13. The Space-to-record listener is wired

- **Expected:** A keyboard listener on `keydown` / `keyup` for the Space key that toggles recording, and an explicit UI cue ("Hold Space to talk").
- **Codifies:** the wispr-style surface the page is meant to clone.
- **Static check:**
  ```bash
  grep -c "Hold Space\|Space.*record\|key.*Space" public/app.html
  # expected: ≥ 1
  ```

## T14. The waveform path is driven by an AnalyserNode

- **Expected:** An `AnalyserNode` is created from the media stream and `getByteFrequencyData` is read into an SVG `path.d`.
- **Codifies:** the live-waveform claim (not a static SVG).
- **Static check:**
  ```bash
  grep -c "AnalyserNode\|getByteFrequencyData\|createMediaStreamSource" public/app.html
  # expected: ≥ 1
  ```

## T15. The /app page is reachable and the wispr demo mirror is untouched

- **Expected:**
  - `GET /app` returns 200 on the preview URL (with Vercel SSO bypass).
  - `GET /app.html` returns 200 on the preview URL.
  - `GET /demo/dist/web-demo.js` returns 200 with byte count 23,666 (the byte-identical wispr mirror).
- **Codifies:** F002, F006.
- **Command:**
  ```bash
  vercel curl -s -o /dev/null -w "%{http_code}\n" "$PREVIEW_URL/app"
  vercel curl -s -o /dev/null -w "%{http_code}\n" "$PREVIEW_URL/app.html"
  vercel curl -s -o /dev/null -w "%{http_code} %{size_download}\n" "$PREVIEW_URL/demo/dist/web-demo.js"
  ```
- **Pass condition:** the three status codes are 200/200/200, and `size_download` is 23,666.

## What "all pass" looks like

```text
T10  PASS  501 branch present + verbatim
T11  PASS  401 branch present + honest SSO message
T12  PASS  200 branch present; no fake transcript markers
T13  PASS  Space-to-record listener present
T14  PASS  AnalyserNode + getByteFrequencyData present
T15  PASS  /app 200, /app.html 200, /demo/dist/web-demo.js 200 (23,666 bytes)
```

If T10-T12 fail, the page is fabricating or hiding a real backend error — that is a hard regression to D001.
If T13-T14 fail, the page is no longer the wispr-style surface it claims to be.
If T15 fails, the deploy is broken or the wispr mirror was modified.
