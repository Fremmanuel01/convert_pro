# Sprint 2 — UX Audit (Phase 1)

**Date:** 2026-09-28
**Scope:** Inspect every user-facing page/flow before changing anything. This is an audit only; no UI was changed to produce it. Sprint 1 functionality and security are preserved.

Method: read every view (`app/views/**`), the Stimulus/JS controllers, layouts, and the routing. Findings are grouped by surface, then synthesized into cross-cutting themes that drive the Sprint 2 plan.

---

## A. Per-surface findings

### 1. Homepage (`pages/home`, 475 lines)
- **No action on the page itself.** It's a pure marketing page; the primary CTA "Start Converting Free" just links to `/tools`. A visitor who came to *do a task* must first understand the site's tool taxonomy before doing anything. This is the core Phase-3 problem.
- **Heavy "AI-SaaS" aesthetic**: orbit rings, three blurred glow blobs (in the layout), a shimmer-text headline, four floating glass file-cards, an animated "Processing" pill, a scrolling marquee of tool names. Decorative, not functional.
- **Inaccurate trust claim**: "all in your browser. No software to install, **no account required**." Server-side tools (19 of 28) upload to the server and require sign-up to download the result. This over-claims (Phase 9).
- **Vanity metrics**: "10,000+ users", "50+ Formats" — unverifiable marketing (the brief says avoid exaggerated claims).
- Inline styles everywhere (`style="background:linear-gradient(...)"`) — not systematized, hard to keep consistent.

### 2. Tool listing / discovery (`tools/index`, 155 lines)
- Only **three filters** (PDF / Images / AI) driven by the registry's 3 coarse categories. No **Convert**, **Documents**, or **Scan & OCR** grouping; conversions between office formats and PDF are all lumped under "PDF Tools".
- **No search.** With 28 tools, a user who knows what they want (e.g. "HEIC") must scan the grid.
- A **"Request Tool" placeholder card** advertises a capability that does nothing (dead affordance).
- Cards are attractive but heavy (`backdrop-blur-xl`, `rounded-3xl`, hover `-translate-y-2` + `rotate-3` on the icon) — the "giant rounded glass cards everywhere" pattern the brief calls out.
- Filtering is bespoke vanilla JS embedded in the view; no reuse.

### 3. Individual tool page (`tools/show`, **848 lines** + ~300 lines inline JS)
- **Monolithic.** One template handles all 28 tools via a long chain of `has_password`, `has_quality`, `has_dpi`, … booleans and per-tool option blocks. There is **no reusable upload component** — the drop zone, preview, options and submit are inlined, and the JS (preview thumbnails, drag/drop, options toggle) lives in a `<script>` in the view.
- Upload zone is decent (drag/drop + browse + preview) but **cannot be reused** by the homepage or any other surface.
- Accepted-format and size info exist but are visually secondary; validation feedback is a full-page redirect with a flash, not inline.
- The client-vs-server split is invisible to the user: some tools finish instantly in-browser, adjacent ones upload + wait + require signup, with no explanation.

### 4. Upload experience
- Two different implementations: the server form (`tools/show`) and the client-side path (`client_tool_controller.js`). Divergent behavior, no shared component (Phase 4).
- Mobile file selection works via the native input, but the custom drop-zone overlay and preview logic are desktop-first.
- Errors surface as a redirect + flash banner, losing the user's place.

### 5. Client-side conversion flows (9 tools)
- Run entirely in-browser (jsPDF/pdf-lib/pdf.js/heic2any). After Sprint 1 they pre-authorize quota via `POST /conversions/log`. On error they use **`alert()`** — a blocking, off-brand browser dialog.
- No unified "processing → result" UI; the file just downloads and the form resets. There's no result screen, no "convert another / next action".

### 6. Server-side conversion flows (19 tools)
- Submit → `ToolRunner` (validate + claim quota + enqueue) → redirect to `conversions/show`. Works, but the handoff to the "processing" screen is abrupt.

### 7. Processing states (`conversions/show`)
- **The single worst UX in the product:** the processing state uses `<meta http-equiv="refresh" content="3">` — a **full-page reload every 3 seconds**. It flashes, resets scroll, and re-renders the whole app shell. There is no staged feedback (Uploading → Processing → Ready), no `aria-live` status, and no graceful in-place transition to the result. This is exactly the Phase-5 target.
- Input files always render a hard-coded `picture_as_pdf` icon regardless of actual type.

### 8. Errors
- Server failures render a reasonable failed card with the raw `error_message` and "Try again / Contact support". Good, but "Try again" links back to the tool with no state carried; and some `error_message`s are engine text.
- Client failures use `alert()`.
- Upload validation errors are redirect + flash (jarring).

### 9. Completed results (`conversions/show`)
- Shows a success card with a Download button (or "Sign up to Download" for guests). **No "Convert another", no next-action recommendations, no output-format chip.** A finished PDF→JPG is a dead end — the user must navigate back to `/tools` and start over. This is the Phase-6/7 opportunity: make it feel like one connected workspace.

### 10. Downloads
- Solid post-Sprint-1: presigned/expiring URLs, ownership-checked, guest→signup claim flow. The auto-download uses a `turbo:load` script injecting an `<a>` click. Functional.

### 11. Login / signup (`devise/sessions/new` 309 lines, `registrations/new` 310 lines)
- Large bespoke auth pages with Google/Firebase sign-in. Not audited for conversion friction in depth, but they're heavy and duplicate a lot of styling. The guest→signup gate lands *after* a server conversion completes, which is the right moment but needs a clear value message ("unlock 5 free downloads").

### 12. Account / dashboard (`pages/dashboard` 232 lines)
- Dashboard + a separate "Analytics" page (per-user counts, not product analytics — confusingly named in the sidebar). Usage meter shows `conversions_count / conversion_limit_per_day`, but the cap is actually a **lifetime** counter (Sprint-1 known issue); the label "per day" is misleading.

### 13. Quota states
- Sidebar shows a usage bar; dashboard has a "limit reached" card; server path redirects to `/billing/upgrade` on `LimitExceededError`; client path redirects to upgrade on 402. Coverage is decent but the messaging is generic ("You have reached your free limit") and doesn't say *what remains* or *what upgrading provides* at the moment of friction (Phase 8).

### 14. Pricing / upgrade surfaces
- `pricing`, `billing/upgrade`, `billing/show`, plus upgrade CTAs in tools/index, sidebar, dashboard. Now render price from `BillingPlans` (Sprint 1). The upgrade page is a single "Proceed to Paystack" button. No clear free-vs-paid value framing beyond a feature list.

### 15. Mobile behavior
- Signed-out: responsive navbar with a full-screen mobile menu overlay — works.
- Signed-in: sidebar becomes an off-canvas drawer — works.
- Tool page drop-zone and preview are desktop-oriented; option grids use `grid-cols-2` which is tight on small screens. The processing meta-refresh is especially bad on mobile (full reload on a slow connection).

### 16. Two-shell inconsistency (layout)
- **`layouts/application` renders two completely different chromes**: signed-out users get the marketing navbar + glow-blob background + footer; signed-in users get an app sidebar + header. The *same tool* looks and navigates differently depending on auth state. A guest converting a file is in "marketing chrome"; the instant they sign up they're dropped into a different "app chrome". This is the biggest structural inconsistency.

---

## B. Cross-cutting themes

1. **No single dominant action.** The product is a directory of forms, not a "give me your file, I'll tell you what you can do" workspace. (Phases 3, 4, 7)
2. **No real-time processing feedback.** Meta-refresh is the standout defect. (Phase 5)
3. **Dead ends after success.** No next actions, no "convert another". (Phases 6, 7)
4. **No reusable components.** Upload, processing, and result UI are re-implemented per surface; the tool page is an 848-line monolith. (Phases 4, 10)
5. **Coarse IA + no search.** 28 tools under 3 buckets, implementation-flavored grouping. (Phase 2)
6. **Trust claims exceed reality.** "No account required / all in your browser" is false for server tools; AI data-egress is undisclosed. (Phase 9)
7. **Aesthetic reads as "AI SaaS demo"** — glow blobs, orbit rings, oversized rounded glass cards, marquee, vanity metrics — not "credible enough to upload a legal contract". (Phase 10)
8. **Quota messaging is generic and slightly dishonest** (per-day label on a lifetime counter). (Phase 8)
9. **Accessibility gaps**: `alert()` dialogs, no `aria-live` on processing, inconsistent focus states, hard-coded file icons. (Phase 11)
10. **Two-shell split** makes the guest→user transition feel like two different products. (Phase 10)

---

## C. What is already good (preserve)
- Sprint 1 security/enforcement: server-side validation, atomic quota, IDOR-safe ownership, rate limiting, retry semantics, analytics event bus — all intact and must not regress.
- The tool registry is clean data and is the right backbone for IA + recommendations.
- Dark mode is wired end-to-end (FOUC-safe inline script).
- The download flow (presigned URLs, guest claim) is solid.
- Conversion history table is clear and functional.

---

## D. Sprint 2 plan implied by this audit (implementation order)
1. **Processing lifecycle (Phase 5)** — replace meta-refresh with a Turbo-Frame status poll that transitions in place with staged, `aria-live` feedback and auto-completion. *Highest impact.*
2. **Deterministic next-action recommender (Phase 7)** + **result experience (Phase 6)** — a registry-driven `ToolRecommender` powering "Convert another / recommended next steps" on the completed screen.
3. **Information architecture (Phase 2)** — richer, user-language categories (PDF · Convert · Images · Documents · Scan & OCR · AI Documents) derived from the real 28 tools, plus instant client-side search on the tools page.
4. **Reusable uploader (Phase 4)** + **homepage upload-first (Phase 3)** — one shared upload partial/controller; a homepage hero that accepts a file, detects its type, and offers only actions that exist.
5. **Trust/privacy (Phase 9), quota UX (Phase 8), visual restraint (Phase 10), a11y/perf (Phase 11), analytics (Phase 12)** — applied across the above.

Non-goals respected: no new converters, no SEO/blog, no pricing changes, no Paystack plan changes, no team/API/native, no replacing Sprint-1 security.
