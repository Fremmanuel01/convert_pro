# OfficeDocTools — Product & Technical Baseline

**Date:** 2026-09-26
**Purpose:** Factual snapshot of the application as it exists today, before any commercial-launch changes. Nothing in this document has been implemented or changed — it is an audit only.
**Stack:** Rails 8.1, PostgreSQL, SolidQueue + SolidCache (no Redis), Active Storage (Cloudflare R2 / Cloudinary), Devise + Google OAuth + Firebase, Paystack, Tailwind, Stimulus/importmap.

---

## 1. Tool Inventory

28 tools are registered in `app/services/tool_registry.rb`. **9 of them are actually executed entirely in the browser** by `app/javascript/controllers/client_tool_controller.js` and never reach the server tool class of the same name (see §2). "Path" below reflects what actually runs.

Route pattern for all: `GET /tools/:tool_id` (form) → `POST /tools?tool_id=:id` (submit).
Server-side size limits (`ToolRunner`): **10 MB free / 100 MB Pro**. Client-side tools enforce **no size limit**. All server tools run in the **background** (SolidQueue); all client tools run **synchronously in the browser**.

| Tool | Slug | Input | Output | Engine / Provider | Path | Size limit | Anon? | Free/Paid | Direct test |
|------|------|-------|--------|-------------------|------|-----------|-------|-----------|-------------|
| Merge PDF | `merge_pdf` | PDF (multi) | PDF | **Browser** pdf-lib *(server: CombinePDF+gs, dead)* | Client | none | Yes | Unlimited (bypasses limit) | No |
| Split PDF | `split_pdf` | PDF | ZIP | **Browser** pdf-lib+fflate *(server: CombinePDF+rubyzip, dead)* | Client | none | Yes | Unlimited | No |
| Compress PDF | `compress_pdf` | PDF | PDF | Ghostscript | Server (bg) | 10/100 MB | Yes | Counts to limit | No |
| Word to PDF | `docx_to_pdf` | DOCX/DOC | PDF | LibreOffice + gs | Server (bg) | 10/100 MB | Yes | Counts | No |
| PDF to Word | `pdf_to_docx` | PDF | DOCX | LibreOffice (+ocrmypdf) | Server (bg) | 10/100 MB | Yes | Counts | No |
| Protect PDF | `protect_pdf` | PDF | PDF | qpdf (`--encrypt`) | Server (bg) | 10/100 MB | Yes | Counts | **Yes** |
| Unlock PDF | `unlock_pdf` | PDF | PDF | **Browser** pdf-lib *(server: qpdf, dead)* | Client | none | Yes | Unlimited | No |
| Images to PDF | `images_to_pdf` | JPG/PNG (multi) | PDF | **Browser** jsPDF *(server: Prawn, dead)* | Client | none | Yes | Unlimited | No |
| PDF to Images | `pdf_to_images` | PDF | ZIP | **Browser** pdf.js+fflate *(server: gs, dead)* | Client | none | Yes | Unlimited | No |
| Webpage to PDF | `webpage_to_pdf` | URL | PDF | Grover (headless Chromium) | Server (bg) | n/a | Yes | Counts | No |
| OCR PDF | `ocr_pdf` | PDF | PDF | ocrmypdf | Server (bg) | 10/100 MB | Yes | Counts | **Yes** |
| Redact PDF | `redact_pdf` | PDF | PDF | Ghostscript flatten **(coordinate redaction NOT implemented — raises)** | Server (bg) | 10/100 MB | Yes | Counts | No |
| Summarize PDF (AI) | `summarize_pdf` | PDF | PDF | pdftotext/ocr + **Groq llama-3.3-70b** + Prawn | Server (bg) | 10/100 MB | Yes | Counts | No |
| HEIC to JPG | `heic_to_jpg` | HEIC | JPG | **Browser** heic2any *(server: MiniMagick, dead)* | Client | none | Yes | Unlimited | No |
| HEIC to PNG | `heic_to_png` | HEIC | PNG | **Browser** heic2any *(server: MiniMagick, dead)* | Client | none | Yes | Unlimited | No |
| WEBP to JPG | `webp_to_jpg` | WEBP | JPG | **Browser** canvas *(server: MiniMagick, dead)* | Client | none | Yes | Unlimited | No |
| WEBP to PNG | `webp_to_png` | WEBP | PNG | **Browser** canvas *(server: MiniMagick, dead)* | Client | none | Yes | Unlimited | No |
| Excel to PDF | `xlsx_to_pdf` | XLSX/XLS | PDF | LibreOffice + gs | Server (bg) | 10/100 MB | Yes | Counts | No |
| PowerPoint to PDF | `pptx_to_pdf` | PPTX/PPT | PDF | LibreOffice + gs | Server (bg) | 10/100 MB | Yes | Counts | No |
| Rotate PDF | `rotate_pdf` | PDF | PDF | qpdf (`--rotate`) | Server (bg) | 10/100 MB | Yes | Counts | No |
| JPG to PNG | `jpg_to_png` | JPG | PNG | ImageMagick (`magick`) | Server (bg) | 10/100 MB | Yes | Counts | No |
| PNG to JPG | `png_to_jpg` | PNG | JPG | ImageMagick | Server (bg) | 10/100 MB | Yes | Counts | No |
| PDF to Text | `pdf_to_text` | PDF | TXT | pdftotext | Server (bg) | 10/100 MB | Yes | Counts | No |
| AI Generate Presentation | `ai_generate_pptx` | Prompt | PPTX | **Claude** (`claude-opus-4-6` ⚠) + hand-rolled OOXML | Server (bg) | n/a | Yes | Counts | No |
| AI Generate Document | `ai_generate_docx` | Prompt | DOCX | **Claude** (`claude-opus-4-6` ⚠) + LibreOffice HTML→DOCX | Server (bg) | n/a | Yes | Counts | No |
| Watermark PDF | `watermark_pdf` | PDF | PDF | Prawn + CombinePDF | Server (bg) | 10/100 MB | Yes | Counts | No |
| AI Translate PDF | `ai_translate_pdf` | PDF | PDF | pdftotext + **Claude** (`claude-opus-4-6` ⚠) + Prawn | Server (bg) | 10/100 MB | Yes | Counts | No |

⚠ `CLAUDE_MODEL = "claude-opus-4-6"` is used in all three AI tools. There is no such published model ID (Opus is `claude-opus-4-8`; `4-6` is the Sonnet line). These three tools most likely fail at runtime with a model-not-found error — **verify against a live key before launch.**

---

## 2. Implementation-path verification (Registry → Runner → Job → class)

Traced every tool from `ToolRegistry` → `ToolsController#create` → `ToolRunner#run!` → `ToolJob#perform` → `Tools::*#process`. Findings that differ from the UI/registry:

- **Dual implementation / dead server code (9 tools).** `client_tool_controller.js` maintains a `clientSideTools` allow-list — `images_to_pdf, merge_pdf, split_pdf, unlock_pdf, pdf_to_images, heic_to_jpg, heic_to_png, webp_to_jpg, webp_to_png` — that calls `event.preventDefault()` and does the whole conversion in the browser. For these, the server classes (`Tools::MergePdf`, `Tools::SplitPdf`, etc.) **never run in normal use**. They are fully implemented but effectively dead code. This has three consequences:
  - **Quota is not enforced** on these 9 tools. The browser does the work, then fire-and-forgets `POST /conversions/log`, which only *increments* a counter — it never blocks. A free user gets **unlimited** merge/split/images→pdf/unlock/pdf→images/heic/webp conversions. The 5-conversion cap only bites the server tools.
  - **No file-size limit** applies to these 9 tools.
  - Two engines can diverge (e.g. browser merge = pdf-lib, server merge = CombinePDF) so output differs depending on which path a future change routes through.
- **`protect_pdf` mismatch.** It has a `processProtectPdf()` case in the JS `switch`, but it is **not** in the `clientSideTools` array, so `preventDefault` never fires and it submits to the **server** (`Tools::ProtectPdf`, qpdf). The client method is unreachable. Harmless today, but a trap.
- **Redact PDF is misleadingly named.** `Tools::RedactPdf` does **not** redact content. If `options['redactions']` is present it *raises* ("requires the hexapdf adapter (pending)"); otherwise it just re-renders through Ghostscript (a flatten/metadata-strip). The UI markets it as "securely drop hidden text blocks" — it removes hidden layers but cannot redact chosen regions.
- **Provider inconsistency.** `Tools::SummarizePdf` calls **Groq** (`llama-3.3-70b-versatile`, `GROQ_API_KEY`) with a comment referencing "GPT-4o-mini," while the UI shows a generic "AI" badge and the AI-generate/translate tools use **Claude**. `GEMINI_API_KEY` is present in `.env` but referenced nowhere in the codebase (dead config).
- **Everything else matches its registry entry** and routes correctly through the background job.

---

## 3. Customer journey map

`Landing (pages#home)` → hero "Start Converting Free" → `/tools` grid (`ToolsController#index`, grouped by category) → tool page (`tools/show`, drop-zone + collapsible options) → **submit**:

- **Client tools (9):** processed in-browser, file auto-downloads immediately, `POST /conversions/log` records activity. **No account, no quota, no email, no server round-trip.**
- **Server tools (19):** `ToolRunner` validates type/size/quota → creates `Conversion(status: pending)` → attaches uploads → enqueues `ToolJob` → redirects to `conversions#show` ("Your files are being processed!").

`Progress` → the show page renders current status. **There is no polling/auto-refresh** — the user must manually reload to see `processing → completed`. → `Download` (`conversions#download`):

- Guest output requires **sign-up/sign-in to download** (`store_location_for` → registration) — the "claim" flow associates the conversion to the new user, counts it against their quota, and emails the result.
- Signed-in users get a presigned R2 URL (10 min) / signed Cloudinary URL / local blob path.

`Quota` (`ConversionLimiter`, 5 lifetime free) → on exceed, redirect to `/billing/upgrade` → `Pricing` ($0 / $5-mo / $50-yr) → `billing#create_subscription` → `PaystackService#initialize_subscription` → Paystack checkout → `billing#callback` (verifies txn, grants Pro as a fallback) **and/or** `webhooks/paystack#create` (authoritative). `Future usage`: Pro users hit the `:priority` queue and 100 MB limit.

**Broken / confusing / unnecessary steps:**
1. **No progress feedback on server tools.** Static show page; user has no signal when the file is ready. Highest-impact conversion-reliability gap.
2. **Forced sign-up gate lands *after* the work is done** for server tools — the user waits, then is asked to register to download. Combined with (1) this is where drop-off will concentrate.
3. **Client vs server split is invisible and inconsistent** — some tools need no account and are instant; adjacent tools require account + wait. Confusing and unmonetizable.
4. **Pricing currency mismatch** (see §6): page says USD, Paystack charges NGN.
5. **`alert()` used for all client-tool errors** — blocks the tab and is off-brand.
6. **`conversions#log` is an open endpoint** (see §4.6) — anyone can inflate/burn counters.

---

## 4. Detailed audit of the seven prior issues

### 4.1 Server-side file validation (magic bytes)
- **Files:** `app/services/tool_runner.rb` (`validate_request!`), `app/services/tools/base_tool.rb`.
- **Now:** trusts client-supplied `file.content_type` only. No byte inspection before handing files to LibreOffice/Ghostscript/qpdf/ocrmypdf — the exact parsers with historical RCE on malformed input. Client tools do zero validation.
- **Smallest correction:** in `validate_request!`, verify the real MIME with `Marcel::MimeType.for(file.tempfile)` (Marcel already ships with Rails, already used in `base_tool.rb`) and compare against `accepted_types`; reject on mismatch. ~5 lines, one file.

### 4.2 Rate limiting / abuse protection
- **Files:** none — no throttling exists anywhere. `ApplicationController` only sets `allow_browser :modern`.
- **Now:** unauthenticated `POST /tools`, `/conversions/log`, `/webhooks/paystack`, and Devise routes are wide open; each server conversion can spawn a 5-minute LibreOffice/gs process.
- **Smallest correction:** add `rack-attack` (one gem) with throttles on `POST /tools` per IP, `/conversions/log` per IP, and Devise sign-in; a global concurrent-job cap. ~1 initializer.

### 4.3 Disabled cleanup scheduling
- **Files:** `config/recurring.yml.bak` (disabled by the `.bak` suffix), `app/jobs/cleanup_conversions_job.rb` (implemented + spec'd, purges Free >24 h / Pro >30 d).
- **Now:** SolidQueue loads `config/recurring.yml`, which does not exist — so cleanup **never runs**. Storage and DB rows grow unbounded; uploaded documents are retained indefinitely (privacy exposure, see §5).
- **Smallest correction:** rename `recurring.yml.bak` → `recurring.yml` and confirm the SolidQueue supervisor is running recurring tasks (note: queue currently runs in-process in Puma — see §5). Zero code change.

### 4.4 AI/provider naming inconsistency
- **Files:** `tool_registry.rb` (labels), `tools/summarize_pdf.rb` (Groq), `tools/ai_generate_pptx.rb`, `ai_generate_docx.rb`, `ai_translate_pdf.rb` (Claude, model `claude-opus-4-6`), `.env` (`GROQ`, `GEMINI` unused, `ANTHROPIC`).
- **Now:** UI implies one "AI"; backend mixes Groq + Claude; `GEMINI_API_KEY` unused; Claude model ID likely invalid.
- **Smallest correction:** pick one provider per capability, fix the model ID to a valid one (`claude-opus-4-8` or a Sonnet/Haiku id), make registry copy match, drop `GEMINI_API_KEY`. Config + string changes only.

### 4.5 Non-atomic quota counter
- **Files:** `app/services/conversion_limiter.rb` (`increment!` → `@user.increment!(:conversions_count)`), `tool_runner.rb` (check-then-increment).
- **Now:** `can_convert?` and `increment!` are separate steps with no lock; concurrent uploads can both pass. Counter is also a **lifetime** total despite `User#conversion_limit_per_day` implying daily.
- **Smallest correction:** replace with an atomic `User.where(id:).update_all("conversions_count = conversions_count + 1")` guarded by a conditional update, or a DB check constraint. Decide and document whether the free cap is lifetime or periodic (currently lifetime).

### 4.6 Authorization of `conversions#log`
- **Files:** `app/controllers/conversions_controller.rb#log`, route `POST /conversions/log`, called from `client_tool_controller.js#reportActivity`.
- **Now:** no auth, no verification. Any client can POST arbitrary `tool_id` repeatedly to create `completed` Conversion rows and increment a signed-in user's counter (or spam guest sessions). It is also the *only* record that a client-side conversion happened, yet enforces nothing.
- **Smallest correction:** require it to be same-origin + CSRF (already sends the token), rate-limit it (§4.2), and treat it as analytics-only (never a quota source of truth). If it isn't needed, remove it.

### 4.7 Retrying permanent failures
- **Files:** `app/jobs/tool_job.rb` (`retry_on StandardError, attempts: 3, wait: 5.minutes`), `base_tool.rb` (re-raises non-timeout errors).
- **Now:** a permanent failure (wrong PDF password, unsupported/corrupt file, invalid AI model) is retried 3× over 15 min, wasting a worker each time, before finally showing the user an error.
- **Smallest correction:** don't retry `Tools::BaseTool::ExecutionError` (permanent) — `retry_on` only for transient classes (`Net::ReadTimeout`, `Errno::*`), `discard_on ExecutionError` with a status update. One file.

---

## 5. Privacy & file lifecycle

- **Where uploads/outputs live.** Active Storage. Production service (`config/environments/production.rb:25`): **Cloudflare R2** (`amazon` S3 adapter, endpoint `…r2.cloudflarestorage.com`, bucket `officedoctools-files`) when `AWS_ACCESS_KEY_ID` is set, otherwise **Cloudinary**. Dev/test: local disk. **The 9 client-side tools never upload at all** — those files stay in the browser (best-case privacy, but inconsistent).
- **Who can access.** `Conversion` rows link to a user (or `user_id: nil` for guests). `conversions#show`/`#download` authorize by `current_user` ownership or by `session[:guest_conversion_ids]`. Object URLs are **presigned and expiring** (R2: 10 min; Cloudinary: signed) — not public-bucket. Reasonable.
- **URL protection.** Download never streams through the app for R2/Cloudinary; it 302s to a signed URL. Brakeman flags this as a weak "unprotected redirect" — acceptable because the target is a self-generated signed URL.
- **Retention.** *Intended:* Free 24 h, Pro 30 d (`CleanupConversionsJob`). *Actual:* **the cleanup job is not scheduled** (§4.3) → **retention is effectively infinite.** This is the single biggest privacy gap for a document tool.
- **Deletion on account removal.** `User has_many :conversions, dependent: :destroy`, and `Conversion has_many_attached` → destroying a user purges conversions and their blobs. Admins can delete users (`admin/users#destroy`); self-serve deletion is only the default Devise "cancel account" (no dedicated UX). Works, but untested for blob cleanup.
- **Temp files after failed jobs.** `BaseTool#call` wraps work in `Dir.mktmpdir { … }`, which removes the temp dir even on exception/timeout. **Temp files do not survive failed jobs** — good. Persisted `input_files`/`output_file` blobs from failed conversions, however, are only removed by the (disabled) cleanup job.
- **Third-party data egress.** Summarize/Translate send **extracted document text** to Groq/Anthropic (up to ~100–120k chars). AI-generate sends the user prompt. Not disclosed in any UI copy or privacy policy — required disclosure before launch.

---

## 6. Monetization

- **Model.** Free = $0, 5 **lifetime** conversions (`ConversionLimiter::FREE_LIMIT = 5`), 10 MB cap, shared `:default` queue. Pro = unlimited, 100 MB, `:priority` queue.
- **Pricing displayed.** `pages/pricing` and `billing/upgrade`: **$5/month, $50/year (USD)**.
- **Pricing charged.** `PaystackService#initialize_subscription` hardcodes `amount_in_kobo` = **500,000 (₦5,000) monthly / 5,000,000 (₦50,000) yearly**, plus a plan code. ₦5,000 ≈ $3.2, not $5 — **currency/label mismatch**; also the amount is passed *alongside* a Paystack plan code, which normally sets its own amount (comment acknowledges the confusion). Verify what the customer is actually billed.
- **Checkout.** `billing#create_subscription` → Paystack `initializeTransaction` (unique `reference`, `callback_url`) → hosted checkout.
- **Activation, two paths:**
  - `billing#callback` verifies the transaction server-side and, if `success`, sets `plan: pro, subscription_status: active` (a "works even if webhook didn't arrive" fallback).
  - `webhooks/paystack#create` — **HMAC-SHA512 verified** (`secure_compare`), **idempotent** (`WebhookEvent` unique event id), transactional. Handles `subscription.create`, `charge.success` (→ active), `subscription.not_renew`/`subscription.disable` (→ cancelled), `invoice.payment_failed` (→ incomplete).
- **Renewal / cancellation.** Renewal relies on Paystack recurring charges → `charge.success` re-activates. Cancellation sets `subscription_status: cancelled` while `plan` stays `pro`; access is correctly revoked because everything gates on `pro? && active?`. **There is no in-app "cancel subscription"** — users must cancel via Paystack; `billing#show` "Manage Billing" just links back to upgrade. No proration, no grace-period UX, no expiry-date tracking.
- **Upgrade prompts.** `tools/index` banner; `_sidebar` ("Upgrade for unlimited"); `pages/dashboard` (button + limit-reached card); `pages/pricing`; `billing/show`; `billing/callback`; and every `LimitExceededError` redirect from `ToolsController#create`. Coverage is good — **except the 9 client-side tools never trigger any upgrade prompt** because they never hit the limiter.

---

## 7. Product analytics

- **What exists.** Only Firebase/GA4 via `measurementId` embedded in `layouts/application.html.erb` — i.e. **automatic pageviews only**. `conversions#log` writes client-tool activity to the DB but not to any analytics sink. `AnalyticsController#index` is a *per-user* dashboard (their own conversion counts), not product analytics.
- **What is NOT measured (no custom events anywhere):**

| Funnel step | Measured? |
|-------------|-----------|
| Homepage → upload/tool start | ❌ |
| Upload → conversion start | ❌ (server rows exist but no event) |
| Conversion success / failure | ❌ (status in DB, not instrumented) |
| Download | ❌ |
| Repeat conversion | ❌ |
| Signup | ❌ |
| Paywall / upgrade view | ❌ |
| Checkout started | ❌ |
| Successful subscription | ❌ |
| Churn / cancellation | ❌ |

- **Consequence:** with a 7-day-to-first-customer goal, there is currently **no way to see where the funnel leaks**. Instrumenting conversion-start, conversion-success/fail, download, signup, paywall-view, and checkout is the minimum to run the launch. All the underlying events already flow through known controller actions — instrumentation is additive, not architectural.

---

## 8. Test suite & static analysis

**Command:** `bundle exec rspec` — **could not run as-is.**

1. **Stale schema blocks the suite.** `db/schema.rb` is at version `2026_02_28_230000`, but migration `20260314120000_add_confirmable_and_admin_to_users.rb` is unapplied and not reflected in the schema. `rails_helper` aborts with `PendingMigrationError`. `db:test:prepare` loads the stale schema and does **not** fix it; only a manual `RAILS_ENV=test rails db:migrate` unblocked the run. **`db:schema:load` on a fresh environment would produce a DB missing the confirmable/admin columns that `User` and `admin/*` depend on** — a deploy/reproducibility blocker.
2. **After forcing the migration: 41 examples, 22 failures, 4 pending.** **All 22 failures share one root cause:** `.env` contains a placeholder `CLOUDINARY_URL = cloudinary://<575342967931164>:<…>@dgjwzaqe3` with literal `<>` brackets → invalid URI. `dotenv-rails` loads `.env` in the **test** environment, and Active Storage raises `URI::InvalidURIError` on nearly every request/model touch. The failures are **environmental, not assertion failures** — the tests themselves appear sound but cannot execute in this config. (Fix: don't load the real `.env` in test, or set a valid/blank `CLOUDINARY_URL` for test.)
3. **Coverage is thin.** Specs exist for models (user, conversion, webhook_event), a few requests (pages, billing, paystack webhook), two services (conversion_limiter, tool_runner), two jobs, `base_tool`, and only **two of 27 tools** (`ProtectPdf`, `OcrPdf`) via `advanced_tools_spec`. The other 25 tools and the entire client-side JS path have **no tests**.

**Brakeman:** clean run, 5 findings, all low-to-medium and all expected:
- 3× "possible command injection" (Medium) in `unlock_pdf`, `xlsx_to_pdf` — **false positives**: all use `Open3.capture3(*array)` (argv form, no shell). Worth confirming the password/option values can't begin with `-` and be read as flags, but not injectable.
- 1× "unsafe reflection `constantize`" (Medium) in `tool_job.rb` — `tool_name` is set only from the server-controlled registry (`class_name`), never user input, so it is safe **as currently wired**; would become dangerous if `tool_name` ever accepted client data.
- 1× "unprotected redirect" (Weak) in `conversions#download` — redirect target is a self-generated signed URL; acceptable.

**bundler-audit:** configured (`config/bundler-audit.yml`) but not run here; recommend running in CI.

---

## Release Blockers
1. **Quota bypass on 9 client-side tools** — free users convert unlimited merge/split/images→pdf/unlock/pdf→images/heic/webp with no account, no limit. Monetization is unenforceable for a third of the catalog. (§2, §4.6)
2. **Cleanup job disabled → indefinite retention of user documents.** Unacceptable privacy posture for a document tool; rename `recurring.yml.bak` and verify it runs. (§4.3, §5)
3. **Stale `schema.rb`** — fresh `db:schema:load` yields a broken DB (missing confirmable/admin). Regenerate schema and get the suite green. (§8)
4. **No server-side file-type validation** before shelling to LibreOffice/gs/qpdf. (§4.1)
5. **No rate limiting / abuse protection** on public conversion + auth + webhook endpoints. (§4.2)
6. **AI tools likely broken** — `claude-opus-4-6` is not a valid model ID; verify all three AI tools against a live key. (§1, §2, §4.4)
7. **Billing currency mismatch** — UI says USD $5/$50, Paystack charges ₦5,000/₦50,000. Confirm and reconcile before taking money. (§6)

## Important Before Launch
1. **Progress feedback for server tools** (poll/Turbo Stream) — biggest conversion-reliability gap; today users must manually reload. (§3)
2. **Minimum funnel analytics** — conversion start/success/fail, download, signup, paywall view, checkout, subscription. Currently blind. (§7)
3. **Third-party AI data-egress disclosure** — document text leaves to Groq/Anthropic with no user notice or privacy policy. (§5)
4. **Fix the test environment** (`CLOUDINARY_URL` placeholder leaking into test) so the suite can gate merges; don't weaken tests to do it. (§8)
5. **Rename or fix "Redact PDF"** — it does not redact regions; the name over-promises. (§2)
6. **Atomic quota counter** and an explicit decision on lifetime-vs-periodic free cap. (§4.5)
7. **Don't retry permanent failures**; surface the real error faster. (§4.7)
8. **In-app subscription cancellation / billing management** (currently Paystack-only). (§6)

## Post-Launch Improvements
1. Delete or consciously keep the 9 dead server tool classes once the client/server strategy is decided (single source of truth per tool).
2. Test coverage for the remaining 25 tools and the client-side JS path.
3. Consolidate AI providers; remove unused `GEMINI_API_KEY`.
4. Move SolidQueue off the web dyno — it currently runs in-process (`plugin :solid_queue` in `config/puma.rb`), so LibreOffice/Ghostscript jobs compete with request serving. Split to a worker dyno as volume grows.
5. Replace `alert()` client-tool errors with in-page UI.
6. Address the Rails 8.2 `ActiveSupport::Configurable` deprecation in `config/application.rb:19`.
7. Lazy/memoize `SOFFICE_BIN = ENV.fetch(..., find_binary)` (runs `which` at class-load in the 5 LibreOffice tools).

## Current Strengths Worth Preserving
1. **Clean tool architecture** — `ToolRegistry` (data) → `ToolRunner` (validate/enqueue) → `ToolJob` → `Tools::BaseTool#process`. Adding a tool is one entry + one subclass.
2. **Robust job hardening** — `Dir.mktmpdir` + Ruby `Timeout` + OS-level `timeout` per shell command; output validation (`validate_pdf!`, <100-byte guard); temp files cleaned even on failure; idempotent `ToolJob`.
3. **Correct payment security** — Paystack webhook HMAC-verified with `secure_compare`, idempotent via `WebhookEvent`, transactional; Firebase tokens cryptographically verified (kid → cached x509 → RS256 with aud/iss).
4. **Shell calls use argv arrays** (`Open3.capture3(*cmd)`) — no shell interpolation.
5. **Expiring, signed download URLs**; no public buckets.
6. **Good secrets hygiene** — `.env` and `master.key` gitignored/untracked; `brakeman` + `bundler-audit` already in the Gemfile.
7. **Privacy-friendly client-side processing** for common image/simple-PDF tools (files never leave the browser) — a genuine selling point if made consistent and intentional.
