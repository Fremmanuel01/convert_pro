module Tools
  class BaseTool
    class ExecutionError < StandardError; end

    # Hard limit: kill the whole job if it runs longer than this.
    # LibreOffice and Ghostscript can occasionally hang on corrupt input.
    JOB_TIMEOUT_SECONDS = 300 # 5 minutes

    attr_reader :conversion

    def initialize(conversion)
      @conversion = conversion
    end

    def call
      @conversion.update!(status: :processing)
      start_time = Time.current

      Timeout.timeout(JOB_TIMEOUT_SECONDS) do
        Dir.mktmpdir("convertpro_#{conversion.id}") do |tmp_dir|
          @tmp_dir = tmp_dir

          input_paths = download_inputs
          output_path = process(input_paths)
          attach_output(output_path)
        end
      end

      elapsed = Time.current - start_time
      @conversion.update!(status: :completed, processing_time: elapsed)
      track_conversion(:conversion_succeeded)
    rescue ExecutionError => e
      # PERMANENT failure: bad / unsupported / password-protected / corrupt input.
      # Retrying would only burn worker capacity, so we do not re-raise. The quota
      # unit is refunded so the user isn't charged for input we can't process.
      Rails.logger.warn("Tool permanent failure [#{self.class.name}] conversion #{@conversion.id}: #{e.message}")
      fail_conversion!(e.message, reason: "permanent")
    rescue Timeout::Error
      # Treated as permanent — a timed-out job should not be retried automatically.
      Rails.logger.error("Tool Timeout [#{self.class.name}] conversion #{@conversion.id}")
      fail_conversion!(
        "Processing timed out after #{JOB_TIMEOUT_SECONDS / 60} minutes. " \
        "The file may be too large, complex, or corrupt.",
        reason: "timeout"
      )
    rescue => e
      # Possibly TRANSIENT (network, resource contention). Mark failed and re-raise
      # so SolidQueue can retry. Quota is refunded only once retries are exhausted
      # (ToolJob), never here, so a later successful retry stays correctly charged.
      Rails.logger.error("Tool Failed [transient] [#{self.class.name}]: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      @conversion.update!(status: :failed, error_message: e.message)
      raise e
    end

    protected

    def process(input_paths)
      raise NotImplementedError, "Subclasses must implement #process(input_paths) returning output file path"
    end

    def tmp_path(filename)
      File.join(@tmp_dir, filename)
    end

    private

    # Mark the conversion permanently failed and refund its quota unit (idempotent).
    def fail_conversion!(message, reason:)
      @conversion.update!(status: :failed, error_message: message)
      @conversion.refund_usage!
      track_conversion(:conversion_failed, reason: reason)
    end

    def track_conversion(event, extra = {})
      tool_id = ToolRegistry.tools.find { |t| t[:class_name] == @conversion.tool_name }&.dig(:id)
      Analytics.track(event, user: @conversion.user, tool_id: tool_id,
                      properties: { path: "server" }.merge(extra))
    end

    def download_inputs
      paths = []
      @conversion.input_files.each_with_index do |file, index|
        # Use sanitized filenames to avoid issues with special characters
        # (spaces, brackets, etc.) that break tools like LibreOffice
        extension = File.extname(file.filename.to_s)
        path = tmp_path("input_#{index}#{extension}")
        File.binwrite(path, file.download)
        paths << path
      end
      paths
    end

    # Returns a `timeout`-prefixed command array for shell tools.
    # The OS-level timeout is more reliable than Ruby's Timeout for child processes.
    def with_timeout(seconds, *cmd)
      ['timeout', seconds.to_s, *cmd]
    end

    # Validates a PDF output file — raises ExecutionError if pages are missing or corrupt.
    def validate_pdf!(path)
      pdf = CombinePDF.load(path)
      raise ExecutionError, "Output PDF has no pages — the conversion produced a blank document." if pdf.pages.empty?
    rescue CombinePDF::PDFException => e
      raise ExecutionError, "Output PDF is corrupt: #{e.message}"
    end

    def attach_output(output_path)
      return unless File.exist?(output_path)

      # Guard: reject suspiciously small files (< 100 bytes = almost certainly empty)
      file_size = File.size(output_path)
      if file_size < 100
        raise ExecutionError,
          "Processing produced an empty or corrupt output file (#{file_size} bytes). " \
          "The input may be blank, password-protected, image-only, or in an unsupported format."
      end

      # Build a human-friendly filename: <original_basename>_converted.<ext>
      input_filename = @conversion.input_files.first&.filename&.to_s
      if input_filename.present?
        input_base = File.basename(input_filename, File.extname(input_filename))
                         .gsub(/[^\w\-]/, "_").squeeze("_").truncate(50, omission: "")
        ext      = File.extname(output_path)
        filename = "#{input_base}_converted#{ext}"
      else
        filename = File.basename(output_path)
      end

      content_type = Marcel::MimeType.for(Pathname.new(output_path))

      @conversion.output_file.attach(
        io:           File.open(output_path),
        filename:     filename,
        content_type: content_type
      )
    end
  end
end
