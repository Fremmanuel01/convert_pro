require 'shellwords'

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

      command = [
        "qpdf",
        "--decrypt",
        "--password=#{password}",
        input_path, output_path
      ].shelljoin

      unless system(command)
        raise ExecutionError, "qpdf decryption failed. Incorrect password or corrupted file."
      end
      
      unless File.exist?(output_path)
        raise ExecutionError, "Failed to generate unlocked output."
      end

      output_path
    end
  end
end
