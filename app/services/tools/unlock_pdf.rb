require 'open3'

module Tools
  class UnlockPdf < BaseTool
    protected

    def process(input_paths)
      if input_paths.size > 1
        raise ExecutionError, "Unlock PDF only accepts a single file."
      end

      input_path = input_paths.first
      output_filename = File.basename(input_path, ".*") + "_unlocked.pdf"
      output_path = tmp_path(output_filename)

      password = @conversion.try(:options)&.dig('password') || ''

      command = with_timeout(60,
        "qpdf",
        "--decrypt",
        "--password=#{password}",
        input_path, output_path
      )

      _stdout, stderr, status = Open3.capture3(*command)
      unless status.success?
        raise ExecutionError, "PDF decryption failed. Incorrect password or corrupted file."
      end

      validate_pdf!(output_path)
      output_path
    end
  end
end
