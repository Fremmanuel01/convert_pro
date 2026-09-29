# Sprint 2.6 Report — Product Consolidation & Commercial Truth

**Date:** 2026-09-29
**Two goals only:** (A) finish product-experience consolidation (retire the `tools/show` monolith, bring auth into the system); (B) remove unsupported commercial claims. No new converters, workflows, SEO or pricing experiments.

**Headline result:** full suite **173 examples, 0 failures**; Brakeman **0 warnings**; bundler-audit **clean**. The 848-line tool-page monolith is gone (now a 30-line shell + partials); auth is on the design system; and every unsupported commercial claim found in a repo-wide audit has been removed or made truthful.

---

## 1. Old monolithic code removed

`app/views/tools/show.html.erb`: **848 lines → 30 lines.** Removed:
- The per-tool markup chain (14 `has_*` boolean branches rendering bespoke option blocks).
- **~310 lines of inline `<script>`**, including a decorative PDF.js thumbnail engine loaded from a **CDN** (`cdnjs.cloudflare.com/.../pdf.js`) that simulated conversion effects on thumbnails, the `settings-preview` panel, and the `toggleOptions()` global.
- Verified gone by test: no `toggleOptions`, no CDN PDF.js, no `settings-preview` in any tool view.

The decorative thumbnail-effects engine was **deleted, not ported** — it placed marketing-style visual noise between the visitor and the converter and pulled a third-party script (a CSP/perf liability). File selection now shows a clean name + size + type-icon list.

## 2. New component architecture

One canonical direct-tool structure, decomposed into focused partials:

| Partial | Responsibility |
|---|---|
| `tools/show.html.erb` (30 lines) | breadcrumb + identity + assembles the card |
| `tools/_trust_note.html.erb` | privacy disclosure (server / browser-private / AI egress) |
| `tools/_uploader.html.erb` | drop zone + file input + preview + hand-off banner |
| `tools/_options.html.erb` | renders options **from registry data** — no per-tool branches |
| `tools/_form.html.erb` | input mode (uploader / URL / prompt) + options + submit |

**Capabilities from data (item 2):** `ToolRegistry::TOOL_OPTIONS` now describes each tool's options declaratively (`{key, label, type, choices, default, hint, group, half, target}`), consumed by one `_options` partial. The view reads accepted types, single/multi-file, input mode (`:prompt`/`:url`/file), AI involvement, size limits, and output type from the registry. Specialized controls (password field with a client-tool target, page ranges, AI audience) plug into the same shell. Adding/altering a tool's options is now a data edit, not new markup.

## 3. JavaScript architecture

Migrated the inline JS into Stimulus, kept controllers focused and composable (no giant replacement controller):
- **`file_drop_controller.js`** (new, ~90 lines): drag/drop, browse, multi-file preview list, remove/clear. Owns only file-selection UX.
- **`client_tool_controller.js`** (unchanged): client-side conversion, quota pre-authorization, analytics, submit interception. Its target names (`fileInput`, `passwordInput`, `submitButton`, `form`) are preserved on the new markup, so client-side tools keep working untouched.
- `poll_controller.js` (processing) unchanged.

Preserved end-to-end: drag/drop, file selection, **multi-file** management, options, client-side conversion, server-side conversion, progress, errors, quota accounting, analytics, results.

## 4. File hand-off between tools (foundation)

A completed output can flow into a compatible next tool without re-selecting the file:
- Result recommendations now link with `from_conversion=<id>`.
- `ToolsController#handoff_for` authorizes it: the source must be a **completed** conversion the requester **owns** (same rules as `ConversionsController`, IDOR-safe) whose **output type the target tool accepts**; server-side tools only.
- The tool page shows a "Using *file* from your last conversion" banner and makes upload optional.
- `ToolRunner` accepts `source_conversion_id`, attaches the prior output as input, and runs the normal validation/quota/size path.
- Not a workflow engine — just the safe primitive. Tested incl. IDOR and type-mismatch rejection.

## 5. Auth redesign (Mobbin-researched)

Mobbin patterns studied (Figma, Clerk, Supabase, Serus): **the form is the primary object** — a centered card, social auth first, `or` divider, email/password, a minimal factual footer. Implemented across **sign in, sign up, password reset (request + edit), confirmation, unlock** using the `odt-*` design system via a shared `auth_shell` + `google` partial (Firebase button/error IDs preserved so Google sign-in still works). Removed the shimmer/rainbow treatment, floating decorations, vanity metrics, "Convert anything / In seconds" marketing, and the inaccurate **"Secure cloud storage — access anywhere"** line. Copy is now concise and factual ("5 free conversions to get started").

## 6. Commercial claim audit (repo-wide)

Grepped the whole repo, not just screenshotted pages. Removed or corrected:

| Claim | Where | Action |
|---|---|---|
| "99.9% Uptime SLA", "50k+ Users", "<2s Avg" | enterprise | **Removed** (fabricated stats) |
| "Team Management", "Dedicated account manager", "API & Integrations", "SSO, audit logs", "Enterprise-grade" | enterprise | **Removed** (features don't exist) |
| "Trusted by teams at Microsoft/Google/Dropbox…" | enterprise | **Removed** (fake logos) |
| "Join thousands of users" | solutions | **Removed** |
| "Popular" segment badge | solutions | **Removed** (no data establishes a segment) |
| "Cloud Storage & History / saved securely in the cloud" | solutions | **Removed** (files are deleted, not stored) |
| "cancel anytime" | pricing, upgrade, upgrade_prompt | **Removed** (no operational in-app cancellation — flagged) |
| **"28 tools"** (there are **27**) | home, footer, nav, pricing, mailer, enterprise | **Fixed** — count now rendered from `ToolRegistry.tools.size`; can never drift again |
| "Secure cloud storage" | login | **Removed** |

No claim was replaced with an invented number. Where evidence isn't derivable from the app, the claim is gone.

## 7. Enterprise simplified

`pages/enterprise` replaced with a **truthful lightweight business-inquiry** page: it explicitly states we *don't yet* offer team accounts, an API, or support contracts, lists only what exists today, and provides a working `mailto:` contact. Nav label changed **"Enterprise" → "For business."** No SLAs, team admin, SSO, dedicated management, or enterprise analytics are advertised.

## 8. Solutions reframed around jobs

`pages/solutions` rebuilt around **real jobs**, each linking to tools that exist: Convert documents · Prepare PDFs · Work with scanned documents · Protect sensitive PDFs · Prepare files for submission · Extract information. No invented audience segments, no vanity counts, no "cloud storage." Nav label **"Solutions" → "What you can do."**

## 9. Homepage CTA hierarchy

The uploader remains the hero (product-as-hero). Above the fold the hierarchy is: **primary** = the file uploader ("What do you need to do with your file?"), **secondary** = "Browse all 27 tools", **tertiary** = "Create a free account" (text link). After a file is selected the uploader transitions into "What you can do with this file" showing only compatible real tools (unchanged, working).

## 10. Semantic tool search

`ToolRegistry::SEARCH_ALIASES` maps everyday phrasings to tools ("make pdf smaller / reduce pdf size" → Compress, "combine documents / join pdf" → Merge, "scan to text / searchable scan" → OCR, "photo to pdf" → Images to PDF, "pdf pages as pictures" → PDF to Images, …). Aliases are folded into each tool card's search dataset, so the existing deterministic client-side filter matches them — **no LLM**.

## 11. Pricing claim audit

Preserved current prices as config placeholders (Sprint 3 owns the pricing decision). Verified/corrected:
- **"2 months free" (yearly): accurate** — monthly ×12 = 6000¢, yearly = 5000¢, difference = 1000¢ = 2 months. Kept.
- **"cancel anytime": removed** — no operational in-app cancellation. (Cancellation is possible via Paystack, but there's no in-app flow, so the claim is gone and flagged below.)
- **"unlimited conversions": kept, flagged for Sprint 3** — Pro genuinely has no conversion cap today (the limiter returns unlimited for active Pro), so it is currently truthful; not silently redefined.
- File-size limits (10 MB / 100 MB), 30-day history, "No credit card required for Free": all accurate.

## 12. Workspace theme research — recommendation

Researched document/productivity workspaces on **Mobbin** (Tana, PandaDoc, SchoolAI, Asana, Obvious, Craft). **Finding:** every one places the *document content* on a **light / off-white canvas**, even when navigation chrome is darker — for readability, contrast against (usually white) document previews, and long-session comfort.

**Recommendation: Option B** — keep the **premium dark identity for marketing** (home, pricing, auth), and move **document-working surfaces** (the tool page, processing, result, dashboard) toward a **light/off-white workspace**. Rationale: readability and long-session comfort on working screens; better contrast for document previews; consistency with the category. This is a **recommendation only** — not implemented this sprint (theme changes weren't in scope and warrant their own focused pass with accessibility/contrast checks).

**Refero MCP: not connected in this environment** — stated plainly; research used Mobbin only. Magic UI/Higgsfield were not used (item 13): the product interaction provides the visual interest; no decorative media was warranted.

## 13. All tools verified (item 14)

Automated verification (`spec/requests/all_tools_render_spec.rb`): for **every** registered tool — (a) its `class_name` resolves to a `Tools::BaseTool` subclass that defines `#process`; (b) its page renders 200 through the new decomposed view in the correct input mode (file / multi-file "multiple" hint / URL / prompt). Multi-file tools (merge, images_to_pdf, split) and client-side tools (heic/webp/jpg/png, merge, split, unlock, images↔pdf) confirmed to render with the right note and multi-file affordance. Representative execution paths (Protect/qpdf, OCR/ocrmypdf, all three AI tools with mocked providers, BaseTool success/permanent-fail/transient-fail) remain covered by the existing suite. **Note:** the registry contains **27** tools, not 28 — corrected in copy (see §6).

## 14. Mobile verification (item 15)

The migrated tool page uses a single responsive column (`max-w-2xl`, full-width uploader/options/submit, `grid-cols-2` only for paired selects that fit ≥360px) with no fixed widths, so there is no horizontal overflow. Mobile rendering of the tool page, homepage and pricing was captured at 390px width during the Sprint 2.5 review pass and confirmed clean. **Limitation this pass:** the automation browser window would not resize below desktop in this session, so a fresh 390px tool-page capture wasn't taken here; the responsive structure is unchanged and was verified previously. Recommend a manual phone pass before launch.

## 15. Files changed
**New:** `tools/_trust_note`, `_uploader`, `_options`, `_form`; `devise/shared/_auth_shell`, `_google`; `file_drop_controller.js`; `spec/requests/{tool_page,all_tools_render}_spec.rb`; `SPRINT_2_6_REPORT.md`.
**Rewritten:** `tools/show.html.erb` (848→30), all `devise/{sessions,registrations,passwords,confirmations,unlocks}` views, `pages/{enterprise,solutions}.html.erb`.
**Modified:** `tool_registry.rb` (options + aliases + `:url` input), `tool_runner.rb` (hand-off), `tools_controller.rb` (hand-off), `conversions/_status.html.erb` (hand-off link), `application_helper.rb` (`tool_count`), `config/initializers/billing_plans.rb` (dynamic count), `shared/_navbar`, `_footer`, `_upgrade_prompt`, `pages/home`, `pricing`, `billing/upgrade`, `devise/mailer/confirmation_instructions`; specs updated for new copy.

## 16. Test / security results
```
bundle exec rspec         → 173 examples, 0 failures
bundle exec brakeman      → 0 warnings
bundle exec bundler-audit → No vulnerabilities found
```
Sprint 1 security (server-side validation, atomic quota/accounting, IDOR — extended to the hand-off path and tested, rate limiting, retry semantics) and Sprint 2 analytics all intact.

## 17. Screenshots provided
Captured live from `127.0.0.1:3001`: (1) homepage, (2) direct PDF tool, (3) direct image tool, (4) multi-file tool, (5) processing, (6) result, (7) login, (8) signup, (9) pricing. (10) mobile direct-tool page — **not re-captured this pass** (browser wouldn't resize; verified at 390px in Sprint 2.5). All are real application states (a test account + seeded conversions; no app code changed to produce them).

## 18. Remaining launch blockers
1. **In-app subscription cancellation is not operational.** "cancel anytime" removed; users can only cancel via Paystack. Build an in-app cancel/billing-portal flow (Sprint 3) before making any cancellation promise.
2. **"Unlimited conversions" (Pro)** — truthful today (no Pro cap) but flagged for the Sprint 3 pricing decision; don't redefine silently.
3. **Redact PDF** still doesn't redact regions (flatten only) — naming/expectation gap from the original baseline, unchanged.
4. **Workspace theme (light working surfaces)** — recommended (Option B), not implemented; needs a focused, accessibility-checked pass.
5. **Lifetime-vs-periodic free cap** decision still open.
6. **Mobile manual pass** on the migrated tool system recommended before launch.

## Non-goals respected
No new converters, no SEO/blog, no pricing experiments (prices preserved as config), no Paystack plan changes, no team accounts/API/enterprise features invented, Sprint 1/2 security untouched, no forced Higgsfield/Magic UI, no decorative AI media.
