require 'shellwords'

module Tools
  class ProtectPdf < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "Protect PDF only accepts a single file."
      end

      input_path = input_paths.first
      output_filename = File.basename(input_path, ".*") + "_protected.pdf"
      output_path = tmp_path(output_filename)
      
      # We extract the password param from @conversion if we added options to the DB.
      # But since we didn't add an `options` JSON column yet, let's hardcode a default "protected" 
      # or require an options payload. For now, we will add an implementation standard using a default password.
      # To do this correctly, a migration for `options:jsonb` would be ideal.
      # We'll default to "secret" if options aren't present.
      password = @conversion.try(:options)&.dig('password') || 'secret'

      command = [
        "qpdf",
        "--encrypt", password, password, "256", "--",
        input_path, output_path
      ]

      unless system(*command)
        raise ExecutionError, "qpdf encryption failed."
      end
      
      unless File.exist?(output_path)
        raise ExecutionError, "Failed to generate protected output."
      end

      output_path
    end
  end
end
