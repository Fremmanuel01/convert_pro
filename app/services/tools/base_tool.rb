module Tools
  class BaseTool
    class ExecutionError < StandardError; end

    attr_reader :conversion

    def initialize(conversion)
      @conversion = conversion
    end

    def call
      @conversion.update!(status: :processing)
      start_time = Time.current

      Dir.mktmpdir("convertpro_#{conversion.id}") do |tmp_dir|
        @tmp_dir = tmp_dir
        
        # Download input files locally for processing
        input_paths = download_inputs

        # Process abstract method (implemented by subclass)
        output_path = process(input_paths)

        # Attach output
        attach_output(output_path)
      end

      elapsed = Time.current - start_time
      @conversion.update!(status: :completed, processing_time: elapsed)
    rescue => e
      Rails.logger.error("Tool Failed [#{self.class.name}]: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      @conversion.update!(
        status: :failed, 
        error_message: e.message
      )
      raise e # Reraise for Job retry handling
    end

    protected

    def process(input_paths)
      raise NotImplementedError, "Subclasses must implement #process(input_paths) returning output file path"
    end

    def tmp_path(filename)
      File.join(@tmp_dir, filename)
    end

    private

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

    def attach_output(output_path)
      return unless File.exist?(output_path)

      # Guard: reject suspiciously small files (< 50 bytes = almost certainly empty)
      file_size = File.size(output_path)
      if file_size < 50
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
