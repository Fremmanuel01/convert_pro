# Sprint 2.5 Report — Design & Conversion System

**Date:** 2026-09-28
**Objective:** Turn the Sprint-2 UX into a coherent, commercial **conversion system** — one design language, an upload-first funnel, honest outcome-based monetization, and contextual upsell — grounded in real-world design research. No new converters, no pricing finalization, no Paystack changes, Sprint 1/2 security preserved.

**Headline result:** full suite **107 examples, 0 failures**; Brakeman **0 warnings**; bundler-audit **clean**. All funnel surfaces render (200) on a fresh boot.

---

## 1. Design research (which patterns influenced what, and why)

Research was done with the **Mobbin MCP** (connected). **Refero MCP and Magic UI MCP are not connected in this environment**, so I relied on Mobbin plus established principles and implemented motion by hand (documented below). No reference was copied wholesale — principles were extracted and synthesized.

| Interaction problem | References studied (Mobbin) | Principle extracted → what we built |
|---|---|---|
| Upload as the hero / product-as-hero | Vimeo (drag-drop + quota beside it), V7, Shuttle, Dropbox | Put the actual tool above the fold; lots of whitespace; the product *is* the CTA → **upload-first hero with the file-identifying uploader**; removed the marketing orbit visual. |
| Processing → success | Google Drive (calm "being processed"), Bonsai ("Your file is ready" + Download), PandaDoc (staged "Imported 1 of 4"), AWS (green success + summary) | Calm, staged, honest; a big obvious Download on success → **staged non-numeric processing** (built Sprint 2) + **clear "Your file is ready" result** with format + size. |
| Free vs paid | Granola ("Unlimited … for free / Upgrade to view older than 30 days"), Current (usage rows: file size, volume), Shuttle ("Everything in Free, plus"), Clerk/Toggl ("No credit card required") | Describe value by **outcome**, not a feature wall; reassure "no credit card" → **outcome-based Free/Pro** cards from config; "No credit card required for Free · cancel anytime". |
| Contextual top-ups | Zaro ("Run low? Top up anytime", honest rate, genuine "BEST VALUE") | Upsell tied to the moment of need, no fake scarcity → **reason-keyed upgrade prompt** (size/quota/batch/ai). |

Full result links are in the conversation; key influences: Vimeo upload, Granola free-vs-pro, Current usage rows, Bonsai success.

### Magic UI
Not connected as an MCP here. Rather than block, I implemented the small set of *restrained* interactions the directive endorses **by hand**: a number **count-up** controller (state acknowledgement), a **success "pop"** keyframe, and calm transitions — all gated behind `prefers-reduced-motion`. No beams, particles, glowing borders or marquees (the directive's banned list — and I removed the pre-existing marquee/orbit/shimmer/float animations).

### Higgsfield (original visuals) — deliberate decision: not used this sprint
Higgsfield is available, but I made the documented call **not** to generate hero imagery/video. Reasoning: (1) the strongest pattern for this product is **product-as-hero** (the live uploader), which already occupies the hero; (2) generated imagery risks reading as "AI-generated," which *undermines* trust for a business-document tool; (3) background media is a Core-Web-Vitals liability the directive explicitly warns against. If we later want a "messy documents → clean output" explainer, it belongs in a below-the-fold section as an optimized, static-fallback asset — a justified fast-follow, not a homepage-hero requirement.

## 2. Product changes
- **Homepage is now a funnel**, not a brochure: upload-first hero → popular tasks (real tools) → "one place for every document task" value → 3-step how-it-works → outcome-based Free/Pro → honest trust (incl. AI data-egress) → final CTA back to the uploader.
- **Honest, outcome-based pricing.** Removed the "Most Popular" badge and the false "5 conversions **per day**" (it's a lifetime allowance). Free and Pro are described by outcome (unlimited, larger files, priority, 30-day history, full AI/OCR). "No credit card required for Free · cancel Pro anytime."
- **Contextual upsell.** Hitting a size limit now explains *the size limit* and offers the larger-file benefit; hitting quota explains *quota*. No single generic modal everywhere.
- **First success respected.** The result screen stays a retention surface (download + convert-another + valid recommendations); the only nudge is a single quiet line, and only when a signed-in Free user has exactly one conversion left — never a modal, never on the first success for anonymous users.
- **Dashboard is a workspace.** Quick-access to frequently used tools (with popular fallback), recent activity, an honest usage meter, and plan state — no vanity charts, no "turn documents into masterpieces" copy.

## 3. UI/UX + design system
- **One system** in `@layer components`: `odt-btn` (primary/secondary/ghost/lg/block), `odt-card`, `odt-input`, `odt-badge`, `odt-eyebrow`, `odt-meter`, plus `odt-pop`/count-up motion. Personality: precise, calm, trustworthy; single accent, restrained radii/shadows, no glass/gradient clutter.
- **De-slopping:** removed the layout glow-blobs (Sprint 2) and now the homepage's orbit ring, shimmer headline, floating file cards, scrolling marquee, and the dashboard's glassmorphism/animated orbs.
- **Copy audit:** buttons describe actions ("Continue to secure checkout", "Add a file", "Browse all tools"); errors explain + offer next step; upgrade copy states the specific benefit; removed hype ("ultra-high-fidelity", "masterpieces", "Revolutionize").
- **Accessibility/motion:** `focus-visible` rings on the new components; all motion respects `prefers-reduced-motion`; no motion competes with the upload action.

## 4. Architectural changes
- **`BillingPlans`** is now the single source for plan **value** (outcome-based `free_features`/`pro_features`, limits read from `AppLimits`) and **contextual upgrade reasons** — so pricing, dashboard, and the upgrade prompt never drift and plan values remain config-driven (directive #8/#11).
- **`ToolRunner::LimitExceededError` carries a `reason`** (size/quota/batch/ai); `ToolsController` forwards it to the upgrade surface and analytics.
- **Reusable partials/controllers:** `shared/_upgrade_prompt` (contextual), `billing_toggle` + `count_up` Stimulus controllers, design-system component classes — reused across pages rather than per-page styles (directive #11).

## 5. No dark patterns (directive #14) — checklist
Verified by test: no "Most Popular", no "per day", no "limited time"; no fake counts/testimonials/countdowns; no preselected paid plan; Pro is emphasized as a *genuine* recommendation only; cancellation and "no credit card" stated plainly; security claims are all truthful and per-tool.

## 6. Analytics (directive #13)
The redesigned funnel maps onto the Sprint-1/2 event bus: `file_selected` (homepage), `tool_viewed` with `source` = home/next/direct, `conversion_started/succeeded/failed`, `result_downloaded`, `quota_reached` **with `reason`**, `upgrade_viewed`, `checkout_started`, `subscription_activated`. No filenames/contents collected. This lets us compare visitor→upload→start→success→download→second-tool→signup→quota→checkout→paid.

## 7. Files changed
**New:** `app/services` (none new — logic in config), `app/views/shared/_upgrade_prompt.html.erb`, `app/javascript/controllers/{billing_toggle,count_up}_controller.js`, `spec/requests/conversion_experience_spec.rb`, `SPRINT_2_5_REPORT.md`.
**Modified:** `config/initializers/billing_plans.rb` (plan value/limits/reasons), `app/services/tool_runner.rb` (reasoned error), `app/controllers/{pages,tools}_controller.rb`, `app/views/pages/{home,pricing,dashboard}.html.erb`, `app/views/billing/upgrade.html.erb`, `app/views/conversions/_status.html.erb`, `app/assets/tailwind/application.css` (design system), `app/javascript/controllers/index.js`, `spec/services/tool_runner_spec.rb`, `PRODUCT_BASELINE.md`.

## 8. Tests added / changed
- **Pricing honesty:** renders Free/Pro, "No credit card required", "cancel anytime"; asserts **absence** of "Most Popular"/"per day"/"limited time"; price from `BillingPlans`.
- **Contextual upgrade:** size-reason and quota-reason copy on the upgrade page; plain confirmation with no reason.
- **Dashboard:** quick access, recent conversions, honest "X of 5 used".
- **`LimitExceededError` reason** (size vs default quota); **`BillingPlans`** value derived from one source.
- Updated the pre-existing size-limit spec to the new (clearer) message.

## 9. Final results
```
bundle exec rspec         → 107 examples, 0 failures
bundle exec brakeman      → 0 warnings
bundle exec bundler-audit → No vulnerabilities found
```
Live boot: `/`, `/pricing`, `/tools`, tool pages all 200; funnel sections and the design system present; no marquee/blob slop.

## 10. Screens to manually inspect
1. **`/` homepage** — hero uploader (drop a PDF → matching tools), popular tasks, value, how-it-works, Free/Pro, trust, final CTA scrolls to `#top`. Check light/dark + a phone width. *(Homepage hero verified via screenshot in Sprint 2; extension was disconnected this sprint so a manual pass is worthwhile.)*
2. **`/pricing`** — monthly/yearly toggle updates price + CTA; confirm no "Most Popular"; "No credit card required".
3. **Contextual upsell** — as a Free user, upload a >10 MB file → the upgrade page should explain the **size** limit specifically; exhaust the 5 conversions → it should explain **quota**.
4. **`/dashboard`** (signed in) — quick-access tools, recent activity, usage meter, contextual prompt.
5. **Result screen** — the single-line "1 free conversion left" nudge appears only at exactly 1 remaining.

## 11. Remaining limitations
- **Tool page (`tools/show`, 848 lines)** still uses its legacy inline uploader/options JS; it now carries trust notes and the design tokens exist, but its internals aren't migrated onto `odt-*` / the reusable uploader yet.
- **No file hand-off** from homepage/result into the next tool (re-select still required) — the recommender + reason plumbing is the backbone for this in Sprint 3.
- **Magic UI / Refero MCPs unavailable** here; motion was hand-built and web-composition research leaned on Mobbin only.
- **Higgsfield media** intentionally deferred (see §1).
- **Auth pages** (sign in/up) not yet on the design system.
- Lower-priority: some hero microcopy still uses inline styles; a full token pass on the signed-in app shell remains.

## 12. Recommendations for Sprint 3
1. **Migrate `tools/show` onto the reusable uploader + `odt-*` system** and split per-tool options into partials — retire the monolith; unifies the last major surface.
2. **File hand-off / workflow chaining** — carry the selected/produced file into the next tool so "convert another / next step" needs no re-upload (biggest remaining funnel friction).
3. **Redesign auth** on the design system (the guest→signup gate is the key money moment) and add **in-app subscription cancellation**.
4. **Analytics dashboard** over `analytics_events` to actually read the funnel this system made measurable, then A/B the hero and pricing.
5. Optional: one **Higgsfield "messy → clean" explainer** as an optimized below-the-fold asset with static fallback.
6. Decide **lifetime vs periodic** free allowance and align config/copy.

---

*Non-goals respected: no new converters, no programmatic SEO, no blog, pricing not finalized, no Paystack plan changes, no team accounts, no API product, no native apps, Sprint 1/2 security untouched, no AI added for visual appeal.*
