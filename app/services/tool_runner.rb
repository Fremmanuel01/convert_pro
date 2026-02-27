class ToolRunner
  class InvalidRequestError < StandardError; end
  class LimitExceededError < StandardError; end

  def initialize(user, tool_id, uploaded_files, options = {})
    @user = user
    @tool_id = tool_id
    @uploaded_files = Array(uploaded_files).reject(&:blank?)
    @options = options
    @tool_meta = ToolRegistry.find(tool_id)
  end

  def run!
    validate_request!
    validate_limits!

    conversion = create_conversion_record!
    attach_files!(conversion)

    # Increment limiter usage
    ConversionLimiter.new(@user).increment!

    # Enqueue background job dynamically applying priority queue
    queue_name = (@user&.pro? && @user&.active?) ? :priority : :default
    ToolJob.set(queue: queue_name).perform_later(conversion.id)
    conversion
  end

  private

  def validate_request!
    raise InvalidRequestError, "Unknown tool: #{@tool_id}" unless @tool_meta
    
    if @tool_meta[:accepted_types].empty?
      # This tool relies on options (e.g. URLs), so files can be empty
    else
      raise InvalidRequestError, "No files uploaded" if @uploaded_files.empty?
      raise InvalidRequestError, "Multiple files not supported for #{@tool_meta[:name]}" if @uploaded_files.size > 1 && !@tool_meta[:accepts_multiple]

      @uploaded_files.each do |file|
        content_type = file.content_type
        unless @tool_meta[:accepted_types].include?(content_type)
          raise InvalidRequestError, "Invalid file type: #{content_type}. Accepted: #{@tool_meta[:accepted_types].join(', ')}"
        end
      end
    end
  end

  def validate_limits!
    limiter = ConversionLimiter.new(@user)
    raise LimitExceededError, limiter.status_message unless limiter.can_convert?

    # Size limits based on plan
    max_mb = @user&.pro? && @user&.active? ? 100 : 10
    total_size = @uploaded_files.sum(&:size)

    if total_size > max_mb.megabytes
      raise LimitExceededError, "File size limit exceeded. Your plan limit is #{max_mb}MB."
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
    @uploaded_files.each do |file|
      conversion.input_files.attach(file)
    end
  end
end
