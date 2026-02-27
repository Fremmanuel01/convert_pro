class ToolJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3 do |job, error|
    conversion = Conversion.find_by(id: job.arguments.first)
    if conversion
      conversion.update!(
        status: :failed,
        error_message: "Job failed after retries: #{error.message}"
      )
    end
  end

  def perform(conversion_id)
    conversion = Conversion.find_by(id: conversion_id)
    return unless conversion

    # Idempotency check: don't process if already done or processing elsewhere
    return if conversion.completed? || conversion.processing?

    tool_class = conversion.tool_name.constantize
    tool_instance = tool_class.new(conversion)
    
    tool_instance.call
  end
end
