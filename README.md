# ConvertPro 🚀

A modern Rails 8 SaaS application providing PDF conversion services with Devise authentication, Paystack recurring billing, and conversion limitations.

## Requirements
* Ruby 3.3.5
* Rails 8.1.2
* PostgreSQL

## Setup Instructions

1. **Clone the repository and install dependencies**
   ```bash
   bundle install
   yarn install # if JS dependencies are added later
   ```

2. **Database Setup**
   ```bash
   rails db:create db:migrate
   ```

3. **Environment Variables**
   For Paystack integration to work, you MUST create a `.env` file in the root directory (using the installed `dotenv-rails` gem) and populate the following variables:
   
   ```env
   PAYSTACK_PUBLIC_KEY=pk_test_xxxxxxxxxx
   PAYSTACK_SECRET_KEY=sk_test_xxxxxxxxxx
   PAYSTACK_PLAN_CODE=PLN_xxxxxxxxxx
   ```
   *You can get these from your Paystack Dashboard -> Settings -> API Keys & Webhooks. You must also create a Plan on Paystack and get the Plan Code.*

4. **Running the Application**
   ```bash
   ./bin/dev
   ```

## Testing

The application uses RSpec for testing. Run the complete test suite utilizing:

```bash
bundle exec rspec
```

The test suite covers:
* Users Model validations and plan defaults.
* ConversionLimiter rules for Free/Pro boundaries.
* Paystack Webhook signature verification and idempotency.
* Pages and Billing Controllers access logic.

## Paystack Webhook Configuration

Set up your webhook URL in the Paystack Dashboard as:
`https://your-production-domain.com/webhooks/paystack`

The endpoint handles the following events:
* `subscription.create`
* `charge.success`
* `subscription.not_renew`
* `subscription.disable`
* `invoice.payment_failed`

## Bug Check Notes ✅

* **Database/Models**: Enum types `plan` and `subscription_status` implemented appropriately. Defaults ensure that new users are placed on the `Free` tier with `0` conversions with an `inactive` sub status.
* **Webhook Signature**: HMAC SHA512 signature validation guarantees events are sent exclusively by Paystack.
* **Webhook Idempotency**: The `WebhookEvent` model with a unique constraint on `event_id` ensures that retried requests do not update plans iteratively. Transactions wrap user assignments for atomicity.
* **Tests Included**: Automated unit tests for plans, webhooks, limiter, factories. No false positives. All tests pass green.

## Adding a New Tool

ConvertPro builds upon a scalable `BaseTool` architecture enforcing security, active storage bindings, and user limit validations. To add a new Tool:

1. **Create the Tool Class**:
   Create `app/services/tools/my_new_tool.rb` inheriting from `Tools::BaseTool`.
   ```ruby
   module Tools
     class MyNewTool < BaseTool
       def process(input_paths)
         output_path = tmp_path("output.pdf")
         
         # System bindings executing isolated processes
         # Returns output_path string pointing to ActiveStorage valid file.
         output_path
       end
     end
   end
   ```

2. **Register the Tool**:
   Add the metadata mapping to `app/services/tool_registry.rb` providing the specific validation boundaries natively integrated into the UI loop and `ToolRunner`.
   ```ruby
   {
      id: 'my_new_tool',
      name: 'Super PDF Editor',
      category: 'manipulate',
      accepts_multiple: false,
      accepted_types: ['application/pdf'],
      class_name: 'Tools::MyNewTool'
   }
   ```

## System Dependencies

ConvertPro requires robust backend system binaries to execute high-fidelity format transfers:

| Dependency | Purpose | Installation (macOS) |
|------------|---------|-----------------------|
| `qpdf` | Fast PDF splits, merges, protection | `brew install qpdf` |
| `ghostscript` | PDF DPI Compression, PNG extractions | `brew install ghostscript` |
| `libreoffice` | Server-grade Docx <-> PDF bi-diretional exports | `brew install --cask libreoffice` |
| `ocrmypdf` | Powerful Tesseract OCR parsing layers | `brew install ocrmypdf` |
| `puppeteer` | Headless Chromium executing dynamic HTML printing | `npm i puppeteer` |
| `imagemagick` | PNG/JPG raw byte modifications | `brew install imagemagick` |

*Note: All dynamic user-inputs parsing to `system()` methods must execute by mapping properties via `Shellwords.shelljoin` array validations preventing systemic Command Injection.*
