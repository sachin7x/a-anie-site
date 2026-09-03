# Open Questions — Unresolved

Each open question is named, dated, and has a known next step.

## Q001. Does the A-Anie desktop app actually run on-device, with no cloud round-trip?

- **OPENED:** 2026-09-03.
- **WHY IT MATTERS:** The marketing copy asserts "on-device", "private", "no cloud". If the desktop app actually does this, the copy is honest. If it doesn't, the copy is fabrication.
- **WHAT WE KNOW:** The marketing text is in place (F010). The desktop binary is not in this repo and cannot be audited from here.
- **NEXT STEP:** Either (a) find the A-Anie desktop repo and audit its network calls, or (b) ask the user to confirm by reading the desktop app's source / running it in a packet sniffer.
- **BLOCKING:** No — the marketing site is shippable as-is. The question is about a claim that the *user's* desktop app is making, which this repo cannot independently verify.

## Q002. ~~Is the /api/contact handler a real email-send or a log-only stub?~~ — RESOLVED 2026-09-03

- **ANSWER:** Log-only stub. See F011.
- **FOLLOWUP:** Update `public/contact.html` and `api/contact.js` to be honest. The success message should say "Logged — I'll see this in the Vercel dashboard" or similar, not "Sachin will reply soon." Add a follow-up task.

## Q003. Does the Vercel SSO bypass header rotate, or is it stable?

- **OPENED:** 2026-09-03.
- **WHY IT MATTERS:** The smoke test depends on `vercel curl` working. If the bypass header rotates, the test needs to be re-keyed.
- **WHAT WE KNOW:** F006 records that `vercel curl` works; the specific header value was redacted in the fact (we kept `KVB5P6Aoxw16pUrQokxqvC0FBA4uf4il` partially — see the observation). It is unclear if the value persists across deploys.
- **NEXT STEP:** Run `vercel curl` against two different preview URLs and compare the bypass header. If stable, no action. If rotated, the test must accept a dynamic header.
- **BLOCKING:** No — but if it rotates, the smoke script needs a refresh step.

## Q004. What is the Prime Agent paper's applicability to the wispr reconstruction?

- **OPENED:** 2026-09-03.
- **WHY IT MATTERS:** Task #50 in the prior session was a 7-question research prompt about the Prime Agent paper. It was interrupted by the user (with /status, /auto-exec, and then the new paper paste) and never closed.
- **WHAT WE KNOW:** Only the abstract was fetched (alphaxiv). Sections and the applicability assessment were never written.
- **NEXT STEP:** Either resume the Prime Agent research (if the user wants it) or close the task as superseded by the new voice-dictation paper (which is what the user just sent). The latter is more likely — the user's "aplly this to current project then harness" was an explicit redirect.
- **BLOCKING:** No — the harness is built around the voice-dictation paper, not the Prime Agent paper.
- **PROPOSED RESOLUTION:** Mark task #50 as superseded; the new paper is the architectural reference.

## Q005. Should the A-Anie marketing site carry a "How to use" walkthrough for the in-browser /app dictation?

- **OPENED:** 2026-09-03.
- **WHY IT MATTERS:** The user constraint "do not delete content from site only focus on UI" forbids copy edits. A new walkthrough page is additive and allowed. But the user also said "use more agent for fast" — they want shipping, not more pages.
- **WHAT WE KNOW:** `/app` exists and surfaces the 401/501 honestly. A walkthrough would be additive copy, not a removal.
- **NEXT STEP:** Ask the user before adding a new page. Do not auto-decide.
- **BLOCKING:** Yes — until the user says yes, no new walkthrough page.

## Q006. Should the harness's verification agent also test the contact form's success path with a real email?

- **OPENED:** 2026-09-03.
- **WHY IT MATTERS:** Q002 is open. The verification agent could close it by submitting a real contact form and checking for a reply. But that requires a working inbox.
- **WHAT WE KNOW:** The contact form's success branch returns 200 with a message (F003). The email side is unknown.
- **NEXT STEP:** Read `api/contact.js` first. If it sends an email, add an inbox-check to the smoke. If it logs, update the UI to be honest.
- **BLOCKING:** No — but pending Q002.
