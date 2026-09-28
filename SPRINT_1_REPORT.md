# Sprint 1 Report — Production Foundation & Commercial Enforcement

**Date:** 2026-09-28
**Scope:** Make the existing product safe, reproducible, enforceable and reliable for launch. No redesign, no new tools, no new pricing tiers, no provider swaps. Architecture (ToolRegistry → ToolRunner → ToolJob → BaseTool) preserved.

**Headline result:** full test suite green (**80 examples, 0 failures**), Brakeman clean (**0 active warnings**), **0 High-severity** dependency advisories remaining. Two product decisions were taken with your input (billing currency → USD; AI model → Sonnet 4.6).

---

## 1. Changes made (by sprint item)

### 1. Test / build environment (reproducible setup)
- Applied the unapplied `AddConfirmableAndAdminToUsers` migration in dev and **regenerated the stale `schema.rb`** (was v20260228, now v20260314+ and includes the new Sprint-1 tables). Fresh `db:schema:load` now yields a correct database.
- Isolated the test environment from real external config: committed a **non-secret `.env.test`** (dotenv loads it before `.env` in test) so an invalid/placeholder `CLOUDINARY_URL` in a developer's `.env` can no longer break the suite. `.gitignore` updated to allow only `.env.test`.
- Repaired stale specs that tested removed implementation (mocked `system` when code uses `Open3.capture3`; a 17-byte fixture tripping the 100-byte output guard). Wired the Devise helper + `rack_test` driver for system specs.

### 2. Authoritative server-side file validation
- `ToolRunner#validate_file_type!` now inspects **actual bytes** via `Marcel::MimeType.for(tempfile, name:, declared_type:)` and only accepts a file whose detected type is permitted for the tool (with a small, documented equivalence map for zip-based OOXML / OLE / HEIF). The browser `content_type` and extension are **secondary** — used only when the signature is genuinely inconclusive.
- Spoofed uploads (e.g. an `.exe` sent as `application/pdf`) are rejected **before** anything reaches LibreOffice/Ghostscript/qpdf/ImageMagick, with a user-friendly message. Rejected files consume no quota.

### 3. Rate limiting & abuse controls
- Added **`rack-attack`** with throttles driven entirely by a central config (`AppLimits::RATE_LIMITS`): anonymous conversions per IP, a stricter bucket for **expensive** tools (AI/OCR/LibreOffice/headless-Chrome), authenticated conversions per user, the accounting endpoint per IP, and auth endpoints (sign-in / sign-up / password) per IP. Health check safelisted; 429 JSON responder; throttles logged.
- Added a **per-user concurrent-job cap** (`AppLimits::MAX_CONCURRENT_JOBS_PER_USER`) in `ToolRunner` so expensive jobs can't be spawned without bound. Upload-size ceilings centralized in `AppLimits`.

### 4. Document lifecycle / cleanup
- **Activated the schedule** (`config/recurring.yml.bak` → `config/recurring.yml`).
- Extended `CleanupConversionsJob` to a full, idempotent retention policy (`AppLimits::Retention`): free (24h), **guest/unassigned (24h — previously never cleaned)**, pro (30d), **stale failed artifacts (6h)**, and **abandoned in-flight jobs (1h → marked failed + quota refunded)**. Temp files remain ephemeral via `Dir.mktmpdir`.

### 5. Quota accounting (close bypasses, atomic, single-charge)
- `ConversionLimiter#claim!` / `#refund!` are **atomic and race-safe** (single conditional `UPDATE`; only one concurrent caller can cross the limit). Replaces the old check-then-`increment!`.
- Every conversion consumes **exactly one** unit; permanent failures **refund** it (`Conversion#refund_usage!`, idempotent via a conditional flag flip). Transient retries never double-charge (unit claimed once at enqueue).
- The 9 client-side tools now call a **server-authoritative, idempotent accounting endpoint before processing** (`POST /conversions/log` with a per-operation UUID). Over-quota → 402 and the browser stops and routes to upgrade. All 28 tools now participate in deliberate accounting.

### 6. Conversion ownership (IDOR)
- Fixed a real IDOR: `ConversionsController#show` previously fell back to loading **any** conversion by id. New `authorized_conversion` scopes access to the owner (signed-in) or the guest session — a signed-in user can no longer read another user's conversion by changing the id. `download` audited and aligned; the accounting endpoint hardened (CSRF-protected, idempotent, quota-gated).

### 7. Retry semantics
- Permanent errors (`Tools::BaseTool::ExecutionError`: bad/unsupported/locked/corrupt input, invalid AI response) are marked failed and **not re-raised → not retried**, and are refunded. Only genuinely transient errors bubble out and are retried (`ToolJob` `retry_on`, 3 attempts), then failed + refunded on exhaustion. `discard_on ExecutionError` as a safety net.

### 8. AI tools — valid, centralized config
- New `AiConfig` is the single source for provider/model/URL/version/key. Replaced the **invalid `claude-opus-4-6`** in all three Claude tools; Summarize continues to use Groq (Llama) and is not labelled as Claude. Default model **`claude-sonnet-4-6`** (your decision), overridable via `ANTHROPIC_MODEL`. Missing key / provider errors fail gracefully.

### 9. Billing currency consistency
- New `BillingPlans` is the single source for price + currency + plan code. **Your decision: charge USD ($5/mo, $50/yr).** `PaystackService` now sends the amount (cents) **and `currency: "USD"`** and reads the plan code from the same source; the pricing and upgrade pages render their prices from `BillingPlans` (no more hard-coded `$` drift). ⚠ Requires a production action (see §7).

### 10. Minimum commercial analytics
- New privacy-preserving `Analytics` + `analytics_events` table. Instrumented all 11 requested events: `tool_viewed`, `file_selected`*, `conversion_started`, `conversion_succeeded`, `conversion_failed`, `result_downloaded`, `signup_completed`, `quota_reached`, `upgrade_viewed`, `checkout_started`, `subscription_activated`. Events record tool + free/paid/anonymous context via a **property whitelist that structurally cannot store filenames or document contents**. (*`file_selected` fires from the client accounting call path.)

### Cross-cutting: dependency security
- `bundle update` (within Gemfile constraints) patched the vulnerable dependencies flagged by bundler-audit: **0 High-severity advisories remain** (puma 8.0.2, nokogiri 1.19.4, jwt 3.3.0, addressable 2.9.0, rack/rack-session, rubyzip path-traversal fix, concurrent-ruby, etc.). Pinned `json ~> 2.19, >= 2.19.9` (the update pulled json 3.0 which broke httparty's `quirks_mode`; 2.19.9 satisfies the CVEs and restores compatibility).
- Removed the `constantize`-on-attribute (unsafe reflection) in `ToolJob` via a name→class lookup table. `config/brakeman.ignore` documents the remaining `Open3.capture3(*argv)` findings as reviewed false-positives (argv form, no shell).

---

## 2. Files changed

**New**
- `.env.test`, `config/initializers/app_limits.rb`, `config/initializers/rack_attack.rb`, `config/initializers/billing_plans.rb`, `config/initializers/ai_config.rb` *(app/services/ai_config.rb)*
- `app/services/analytics.rb`, `app/models/analytics_event.rb`
- `db/migrate/20260926120000_add_usage_accounting_to_conversions.rb`, `db/migrate/20260926120100_create_analytics_events.rb`
- `config/brakeman.ignore`
- Specs: `spec/requests/conversions_spec.rb`, `spec/requests/rate_limiting_spec.rb`, `spec/services/analytics_spec.rb`, `spec/services/tools/ai_tools_spec.rb`
- `PRODUCT_BASELINE.md` (Sprint 1 status section appended), `SPRINT_1_REPORT.md`

**Modified**
- `app/services/tool_runner.rb`, `app/services/conversion_limiter.rb`, `app/services/paystack_service.rb`
- `app/services/tools/base_tool.rb`, `ai_generate_pptx.rb`, `ai_generate_docx.rb`, `ai_translate_pdf.rb`, `summarize_pdf.rb`
- `app/models/conversion.rb`, `app/models/user.rb`
- `app/controllers/application_controller.rb`, `tools_controller.rb`, `conversions_controller.rb`, `billing_controller.rb`, `webhooks/paystack_controller.rb`
- `app/jobs/tool_job.rb`, `app/jobs/cleanup_conversions_job.rb`
- `app/javascript/controllers/client_tool_controller.js`
- `app/views/pages/pricing.html.erb`, `app/views/billing/upgrade.html.erb`
- `config/recurring.yml` (renamed from `.bak`), `db/schema.rb`, `Gemfile`, `Gemfile.lock`, `.gitignore`
- Repaired specs: `base_tool_spec.rb`, `advanced_tools_spec.rb`, `tool_runner_spec.rb`, `conversion_limiter_spec.rb`, `file_upload_spec.rb`, `conversion_spec.rb`, `tool_job_spec.rb`, `cleanup_conversions_job_spec.rb`, `webhook_event_spec.rb`, `spec/rails_helper.rb`

---

## 3. Tests added

17 spec files, **80 examples**. New/expanded coverage:
- **File validation** (`tool_runner_spec`): genuine PDF accepted; spoofed exe rejected; PNG→PDF-tool rejected; zip-based OOXML accepted; rejected file consumes no quota.
- **Atomic quota** (`conversion_limiter_spec`): claims exactly FREE_LIMIT then refuses; racing claims can't exceed the limit; active-Pro unlimited without touching the counter; lapsed-Pro blocked; refund never below zero.
- **Ownership / accounting** (`conversions_spec`): owner can view; other user cannot (IDOR); guest conversion not viewable by non-owner; download IDOR blocked; accounting endpoint charges once, is idempotent per operation id, returns 402 at quota, rejects unknown tool.
- **Retry / refund** (`base_tool_spec`): permanent `ExecutionError` not re-raised + refunded; transient error re-raised + not refunded. (`tool_job_spec`): discard/retry handlers registered; completed-job no-op; unregistered tool name fails safely; registered tool dispatched.
- **Cleanup** (`cleanup_conversions_job_spec`): free/guest/failed purged past window; pro kept within 30d; abandoned in-flight reclaimed + refunded.
- **AI tools** (`ai_tools_spec`): valid centralized model id; sends configured model; graceful failure on provider error and missing key (WebMock — no live spend).
- **Analytics** (`analytics_spec`): whitelisted event recorded with context; unknown events ignored; sensitive properties (filenames/contents) dropped; never raises into the caller.
- **Rate limiting** (`rate_limiting_spec`): anonymous conversion flood and login flood return 429.

No tests were weakened to pass. Where a test asserted removed behavior, it was updated to assert the actual (improved) behavior, with the reason noted in the diff.

---

## 4. Test results

```
bundle exec rspec
80 examples, 0 failures, 0 pending
```
Reproducible from a clean checkout: `bin/rails db:prepare && RAILS_ENV=test bin/rails db:test:prepare && bundle exec rspec`.

---

## 5. Security scan results

**Brakeman 8.0.6:** `Security Warnings: 0` (7 findings ignored via `config/brakeman.ignore`, each documented — all are `Open3.capture3(*argv)` argv-form shell-outs with no shell interpretation; the previously-flagged `constantize` RCE was eliminated in code).

**bundler-audit:** **0 High-severity** advisories after patching. A number of lower-severity (Medium/Low/Unknown) advisories remain only where the fix is a not-yet-released or out-of-constraint dependency bump; none is High. Re-run: `bundle exec bundler-audit check --update`.

---

## 6. Unresolved / follow-ups (not in Sprint 1 scope)

- **Progress feedback for server tools** (polling/Turbo Stream) — still absent; the show page needs a manual reload. High-impact conversion-reliability item, deferred to a UI sprint.
- **In-app subscription cancellation / billing portal** — cancellation is still Paystack-side only.
- **Analytics dashboard** — events are captured to `analytics_events`; no reporting UI yet (query directly for now).
- **Residual non-High dependency advisories** — track and clear as upstream releases land.
- **Client-side accounting is best-effort** — a technically sophisticated user could bypass browser code (files never touch the server for those 9 tools). Enforcement targets ordinary usage; the server path and all quota-bearing operations are authoritative. Documented, accepted for launch.
- **`GEMINI_API_KEY`** is unused; safe to remove from environment (left `.env` untouched).

---

## 7. Manual production checks you must perform

1. **Run migrations on deploy.** Production must run `bin/rails db:migrate` (release phase) to apply `AddConfirmableAndAdminToUsers` + the two Sprint-1 migrations. Verify the `users` table has `confirmed_at`/`admin` and `conversions` has `usage_counted`/`client_operation_id`.
2. **Billing = USD (ACTION REQUIRED).** You chose to charge USD ($5/$50). Before taking payments: (a) confirm the Paystack account supports USD, (b) create **USD** subscription plans and point `PAYSTACK_MONTHLY_PLAN_CODE` / `PAYSTACK_YEARLY_PLAN_CODE` at them, (c) do a live test charge and confirm the customer is billed exactly $5 / $50. This is an effective price change for existing NGN customers — decide on comms/grandfathering.
3. **AI model / keys.** Confirm `ANTHROPIC_API_KEY` and `GROQ_API_KEY` are set in production. Default model is `claude-sonnet-4-6`; set `ANTHROPIC_MODEL` if you want to override. Run one live AI conversion of each type to confirm the model id is accepted.
4. **Recurring cleanup is running.** Confirm the SolidQueue supervisor picks up `config/recurring.yml` (it currently runs in-process via the Puma `solid_queue` plugin) and that `CleanupConversionsJob` executes daily. Verify blob deletion actually occurs on your storage backend (**R2 or Cloudinary**) by checking an old conversion's files are gone after a run.
5. **Rate limits sane for your traffic.** Defaults live in `AppLimits::RATE_LIMITS` (overridable via ENV). Confirm they don't block legitimate office usage at your expected volume; tune `RL_*` env vars if needed.
6. **Rack::Attack cache.** In production it uses `Rails.cache` (SolidCache). Confirm SolidCache is configured so throttle counters persist across requests.
7. **`.env` hygiene.** The real production secrets are set via your host's env (not `.env`). The committed `.env.test` contains only dummy values — verify no real secret leaked into it.
