class ToolRunner
  class InvalidRequestError < StandardError; end

  # Carries a `reason` (quota / size / batch / ai) so the UI can show a
  # contextual upgrade prompt instead of a generic one.
  class LimitExceededError < StandardError
    attr_reader :reason
    def initialize(message, reason: "quota")
      super(message)
      @reason = reason
    end
  end

  # Marcel sometimes reports the container/base type rather than the specific
  # office format (OOXML files are zips; legacy Office files are OLE compound
  # documents; HEIC is a HEIF variant). These are the ONLY relaxations to the
  # authoritative magic-byte check, and only when the declared type matches too.
  SIGNATURE_EQUIVALENTS = {
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"   => %w[application/zip],
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"         => %w[application/zip],
    "application/vnd.openxmlformats-officedocument.presentationml.presentation" => %w[application/zip],
    "application/msword"           => %w[application/x-ole-storage application/x-cfb],
    "application/vnd.ms-excel"     => %w[application/x-ole-storage application/x-cfb],
    "application/vnd.ms-powerpoint"=> %w[application/x-ole-storage application/x-cfb],
    "image/heic"                   => %w[image/heif]
  }.freeze

  # Types that carry no usable signature — fall back to the secondary
  # (declared content-type) check instead of hard-rejecting.
  INCONCLUSIVE_TYPES = %w[application/octet-stream text/plain inode/x-empty].freeze

  def initialize(user, tool_id, uploaded_files, options = {}, source_conversion_id: nil)
    @user = user
    @tool_id = tool_id
    @uploaded_files = Array(uploaded_files).reject(&:blank?)
    @options = options
    @tool_meta = ToolRegistry.find(tool_id)
    # File hand-off: a prior conversion whose output becomes this tool's input.
    # The controller has already authorized ownership + type match.
    @source_conversion = source_conversion_id.present? ? Conversion.find_by(id: source_conversion_id) : nil
  end

  def run!
    validate_request!
    validate_size!
    validate_concurrency!

    conversion = create_conversion_record!

    # Atomically consume one quota unit BEFORE doing expensive work. On failure
    # the record is removed so no orphan/quota leak remains.
    limiter = ConversionLimiter.new(@user)
    unless limiter.claim!(@tool_id)
      conversion.destroy
      raise LimitExceededError.new(limiter.status_message(@tool_id), reason: limiter.block_reason(@tool_id))
    end
    conversion.update!(usage_counted: metered_user?)

    attach_files!(conversion)

    queue_name = (@user&.pro? && @user&.active?) ? :priority : :default
    ToolJob.set(queue: queue_name).perform_later(conversion.id)
    conversion
  end

  private

  # A free user actually consumes a countable unit; anonymous and active-Pro do not.
  def metered_user?
    @user.present? && @user.free?
  end

  def validate_request!
    raise InvalidRequestError, "Unknown tool: #{@tool_id}" unless @tool_meta

    return if @tool_meta[:accepted_types].empty? # URL / prompt tools take no files
    return if handoff_source? # source output already type-checked by the controller

    raise InvalidRequestError, "No files uploaded" if @uploaded_files.empty?
    if @uploaded_files.size > 1 && !@tool_meta[:accepts_multiple]
      raise InvalidRequestError, "Multiple files not supported for #{@tool_meta[:name]}"
    end

    @uploaded_files.each { |file| validate_file_type!(file) }
  end

  # Valid hand-off source: a completed conversion whose output type this tool accepts.
  def handoff_source?
    return false unless @source_conversion&.completed? && @source_conversion.output_file.attached?
    @tool_meta[:accepted_types].include?(@source_conversion.output_file.blob.content_type)
  end

  # Authoritative validation: inspect the actual bytes and confirm the detected
  # type is permitted for this tool. The browser-supplied content-type and the
  # filename extension are only used as a secondary signal when the bytes are
  # inconclusive — never to override a mismatch.
  def validate_file_type!(file)
    detected = detected_mime(file)
    accepted = @tool_meta[:accepted_types]

    return if acceptable_signature?(detected, accepted)

    if INCONCLUSIVE_TYPES.include?(detected)
      # Secondary check: trust the declared type + extension only when the
      # signature is genuinely uninformative.
      return if accepted.include?(file.content_type) && extension_plausible?(file, accepted)
    end

    raise InvalidRequestError,
      "\"#{file.original_filename}\" doesn't look like a supported file for #{@tool_meta[:name]}. " \
      "Expected #{human_types(accepted)}."
  end

  def detected_mime(file)
    io = file.tempfile
    io.rewind
    Marcel::MimeType.for(io, name: file.original_filename, declared_type: file.content_type)
  ensure
    file.tempfile.rewind rescue nil
  end

  def acceptable_signature?(detected, accepted)
    return true if accepted.include?(detected)

    accepted.any? { |type| Array(SIGNATURE_EQUIVALENTS[type]).include?(detected) }
  end

  def extension_plausible?(file, accepted)
    ext = File.extname(file.original_filename.to_s).downcase.delete(".")
    return true if ext.blank? # nothing to contradict
    accepted.any? { |type| Array(Marcel::TYPE_EXTS[type]).include?(ext) } ||
      Array(Marcel::TYPE_EXTS[file.content_type]).include?(ext)
  end

  def human_types(accepted)
    accepted.filter_map { |t| Array(Marcel::TYPE_EXTS[t]).first&.upcase }.uniq.join(", ").presence ||
      "a supported format"
  end

  def validate_size!
    max_mb = AppLimits.max_upload_mb(@user)
    total_size = handoff_source? ? @source_conversion.output_file.byte_size : @uploaded_files.sum(&:size)
    if total_size > max_mb.megabytes
      raise LimitExceededError.new("This file is larger than your #{max_mb} MB limit.", reason: "size")
    end
  end

  # Cap concurrent in-flight jobs per user so expensive native processes can't
  # be spawned without bound. Anonymous users are covered by IP rate limiting.
  def validate_concurrency!
    return if @user.nil?
    in_flight = @user.conversions.where(status: [Conversion.statuses[:pending], Conversion.statuses[:processing]]).count
    if in_flight >= AppLimits::MAX_CONCURRENT_JOBS_PER_USER
      raise LimitExceededError,
        "You have #{in_flight} conversions still processing. Please wait for them to finish before starting more."
    end
  end

  def create_conversion_record!
    Conversion.create!(
      user: @user,
      tool_name: @tool_meta[:class_name],
      status: :pending,
      options: @options
    )
  end

  def attach_files!(conversion)
    if handoff_source? && @uploaded_files.empty?
      blob = @source_conversion.output_file.blob
      conversion.input_files.attach(io: StringIO.new(blob.download), filename: blob.filename.to_s, content_type: blob.content_type)
    else
      @uploaded_files.each { |file| conversion.input_files.attach(file) }
    end
  end
end
