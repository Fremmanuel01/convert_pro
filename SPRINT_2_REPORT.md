# Sprint 2 Report — Product Experience & Conversion UX

**Date:** 2026-09-28
**Objective:** Move OfficeDocTools from "28 utility forms" toward a polished, connected office-productivity product — organised around *"Everything you need to get a document ready for work."* No new converters, no pricing changes, no SEO. Sprint 1 security/enforcement preserved.

**Headline result:** full suite **98 examples, 0 failures**; Brakeman **0 warnings**; bundler-audit **clean**. Every page renders (200) in a live boot. The single worst baseline defect — the 3-second full-page meta-refresh during processing — is gone, replaced by in-place staged updates.

---

## 1. Product changes

- **Live processing (no more manual reloads).** The processing screen now transitions **Uploading → Processing → Preparing result → Ready** in place. When the job finishes it becomes the result view automatically; on failure it shows a human-readable error with retry. No fake percentages — indeterminate/staged only.
- **Upload-first homepage.** The hero now leads with *"What do you need to do with your file?"* Drop a file and it identifies the type and shows **only the tools that actually accept it** (registry-driven; no dead options). Browsable tools remain below.
- **Connected workspace, not 28 islands.** Every completed conversion now offers **Download**, **Convert another**, and **deterministic next-step recommendations** (e.g. a produced PDF surfaces Compress/Split/PDF→Word). Recommendations can never be dead — they're computed from which tools accept the produced output type.
- **Findable tools.** The tools page is reorganised into user-language groups — **PDF Tools · Convert · Images · Scan & OCR · AI Documents** — with **instant search** and category tabs.
- **Honest trust & privacy.** Removed the false "no account required / all in your browser" universal claim. Each tool page now states the truth for *that* tool: server tools ("encrypted, validated server-side, auto-deleted"), client tools ("runs entirely in your browser — never uploaded"), and AI tools carry an explicit **third-party AI data-egress disclosure** before submission.
- **Clearer free plan.** Sidebar quota now reads "X of 5 used", shows remaining, and states what Pro provides — instead of a misleading "per day" label on a lifetime counter.

## 2. UI/UX changes

- Replaced blocking `alert()` client-tool errors with a non-blocking inline `role="alert"` banner.
- Restrained visual pass (Phase 10): removed the layout glow-blobs, orbit-ring hero animation, shimmer text, floating cards and vanity metrics ("10,000+ users"); lighter cards (less `blur`/`rounded-3xl`); honest footer (dropped "Cloud Sync"/"Enterprise Security" for real attributes).
- Accessibility (Phase 11): visible `focus-visible` rings on primary actions and recommendation/upload controls; `aria-live` on the processing status; keyboard-operable uploader (Enter/Space); labelled search; reduced/removed decorative motion.
- Reusable **uploader** component (partial + Stimulus controller) with drag/drop, file picker, preview (name + size), remove, and accepted-format/size info — first-class on mobile via the native input.

## 3. Architectural changes

- **`ToolRecommender`** (`app/services/tool_recommender.rb`): deterministic, explainable next-actions derived from the tool registry by output MIME type. No AI call.
- **Information architecture on the registry** (`ToolRegistry::GROUPS`, `group_for`, `groups`, `file_tool_index`) — a single source powering the tools page, homepage identification, and recommendations. Invariant-tested: every tool belongs to exactly one group.
- **Processing lifecycle without adding Turbo.** The app had no Turbo (Stimulus only). Rather than introduce app-wide Turbo Drive mid-sprint (a behavioral risk), the poller is a small Stimulus controller that fetches an ownership-checked `GET /conversions/:id/status` HTML fragment and swaps itself in place until terminal. Reuses the Sprint-1 `authorized_conversion` guard, so it cannot leak another user's conversion.
- **Reusable upload + tool-filter Stimulus controllers**; component CSS in `@layer components` (no per-tool bespoke styles).
- **Funnel analytics** on the Sprint-1 bus: new whitelisted, rate-limited `POST /events` (`file_selected`) + source attribution (`home`/`next`/`direct`) on `tool_viewed` — the redesigned funnel is now measurable end-to-end without recording filenames or contents.

## 4. Files changed

**New**
- `app/services/tool_recommender.rb`
- `app/controllers/events_controller.rb`
- `app/views/conversions/_status.html.erb`, `app/views/shared/_uploader.html.erb`
- `app/javascript/controllers/{poll,uploader,tool_filter}_controller.js`
- `SPRINT_2_UX_AUDIT.md`, `SPRINT_2_REPORT.md`
- Specs: `spec/services/tool_recommender_spec.rb`, `spec/requests/{conversion_status,discovery,events}_spec.rb`

**Modified**
- `app/services/tool_registry.rb` (IA), `app/controllers/{pages,tools,conversions}_controller.rb`
- `app/views/pages/home.html.erb`, `app/views/tools/{index,show}.html.erb`, `app/views/conversions/show.html.erb`
- `app/views/shared/{_sidebar,_footer}.html.erb`, `app/views/layouts/application.html.erb`
- `app/javascript/controllers/{index,client_tool}_controller.js`
- `app/assets/tailwind/application.css` (component layer), `config/routes.rb`, `config/initializers/rack_attack.rb`

## 5. Tests added / changed

New coverage (all passing):
- **Recommender**: PDF→PDF-tools excluding the tool that ran; JPG→image tools; **zip output → zero dead recs**; none when no output; respects limit.
- **Processing status**: owner sees live processing frame (`data-poll-active-value="true"`); completed renders download + recommendations + `active=false`; failure renders graceful message; **IDOR — another user gets 404**.
- **Discovery**: homepage renders upload-first + tool index + honest trust copy; tools page renders groups/search/tabs; **IA invariant — every tool in exactly one group**; `file_tool_index` excludes prompt/URL tools.
- **Events/funnel**: whitelisted `file_selected` recorded; unknown event rejected (422); `tool_viewed` source attribution (home/next/direct, sanitised).

## 6. Final test results

```
bundle exec rspec        → 98 examples, 0 failures
bundle exec brakeman     → 0 security warnings (7 documented Open3 ignores)
bundle exec bundler-audit→ No vulnerabilities found
```
Sprint-1 security controls verified intact: server-side validation, atomic quota, IDOR-safe ownership (extended to the new status endpoint), rate limiting (now covers `/events`), retry semantics.

## 7. Pages to manually inspect

Boot: `CLOUDINARY_URL=<valid-or-dummy> bin/dev` (or `bin/rails server`) — see the `.env` note in Sprint 1 §7.

1. **`/` homepage** — upload-first hero; drop a PDF and a JPG and confirm only matching tools appear; check dark/light and mobile widths. *(Verified rendering in this sprint — screenshot captured.)*
2. **`/tools`** — grouped sections; type "heic"/"word"/"compress" in search; click category tabs; confirm empty-state.
3. **`/tools/compress_pdf`** (server), **`/tools/merge_pdf`** (client), **`/tools/summarize_pdf`** (AI) — confirm the correct trust note on each (encrypted/auto-deleted, browser-private, AI data-egress disclosure).
4. **Server conversion end-to-end** — upload to Compress PDF, watch the processing screen advance and **auto-flip to the result with no reload**, then use "Convert another" and a recommendation.
5. **Result recommendations** — run PDF→Images (zip output → no recs, correct) vs Compress PDF (PDF output → PDF-tool recs).
6. **Quota** — as a free user near/at 5, check the sidebar meter copy and the upgrade framing.
7. **Failure state** — submit a deliberately bad file and confirm the graceful failure card + retry.

## 8. Remaining limitations

- **Tool page is still the 848-line monolith.** The reusable uploader powers the homepage; migrating all 28 per-tool forms onto it (and removing the inline preview JS) is deferred to keep this sprint's diff safe. The tool page works and now carries trust notes, but its internals weren't refactored.
- **No file hand-off from homepage to tool.** Homepage identification routes to the tool page where the user re-selects the file. Carrying the file across (Sprint 3) would remove that second step.
- **No Turbo.** Polling is a lightweight custom swap; adopting `turbo-rails` later would enable Turbo Streams and simplify this.
- **`file_selected` is best-effort** (client fetch, fail-open) — consistent with the client-side accounting model; funnel truth for server steps remains server-authoritative.
- **Lifetime-vs-periodic free cap** is still a product decision (copy is now honest either way).
- **Auth pages (sign in/up)** were not redesigned this sprint.
- Lower homepage sections (marquee, "how it works", "built for reliability") remain from the old page; they're acceptable but not yet part of the restrained system.

## 9. Recommendations for Sprint 3

1. **Migrate all tool pages onto the reusable uploader** and extract the per-tool options into small partials — retire the monolith.
2. **File hand-off / workflow chaining** — carry the selected (or produced) file from homepage/result directly into the next tool, so "Convert another / next step" needs no re-upload. The recommender is already the backbone for this.
3. **Adopt `turbo-rails`** for Turbo Streams (simpler live updates, form submissions without full reloads) once regression coverage is in place.
4. **Redesign auth** for conversion (the guest→signup gate is the key funnel moment) and add the **in-app billing/cancellation** deferred from Sprint 1.
5. **Analytics dashboard** over `analytics_events` to actually read the funnel this sprint made measurable.
6. Decide **lifetime vs periodic** free allowance and align copy/config.
7. Finish the visual system on the remaining homepage sections and the dashboard.

---

*Non-goals respected: no new converters, no programmatic SEO, no blog, no pricing changes, no Paystack plan changes, no team accounts, no API product, no native apps, no replacement of Sprint-1 security, no AI added for visual appeal.*
