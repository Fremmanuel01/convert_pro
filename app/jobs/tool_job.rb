class ToolJob < ApplicationJob
  queue_as :default

  # Permanent failures (bad/unsupported/locked/corrupt input) are handled inside
  # BaseTool: marked failed, refunded, and NOT re-raised — so they never reach the
  # retry machinery. This is a safety net in case one is ever raised directly.
  discard_on Tools::BaseTool::ExecutionError

  # Only errors reasonably considered transient bubble out of BaseTool. Retry a
  # few times; if still failing, mark failed and refund the quota unit. The unit
  # was claimed once at enqueue time, so retries never double-charge and a later
  # successful retry stays correctly charged.
  retry_on StandardError, wait: 30.seconds, attempts: 3 do |job, error|
    conversion = Conversion.find_by(id: job.arguments.first)
    next unless conversion

    conversion.update!(status: :failed,
                       error_message: "Processing failed after several attempts. Please try again.")
    conversion.refund_usage!

    tool_id = ToolRegistry.tools.find { |t| t[:class_name] == conversion.tool_name }&.dig(:id)
    Analytics.track(:conversion_failed, user: conversion.user, tool_id: tool_id,
                    properties: { path: "server", reason: "transient_exhausted" })
  end

  # Map of registered tool class-name -> resolved Class. Built once at load from
  # trusted ToolRegistry data (constant literals), so we never call constantize on
  # a stored attribute at runtime — the stored name is only ever used as a lookup
  # key, which closes the unsafe-reflection vector entirely.
  TOOL_CLASSES = ToolRegistry.tools.each_with_object({}) do |t, map|
    map[t[:class_name]] = t[:class_name].constantize
  end.freeze

  def perform(conversion_id)
    conversion = Conversion.find_by(id: conversion_id)
    return unless conversion

    # Idempotency: don't reprocess something already done or in flight elsewhere.
    return if conversion.completed? || conversion.processing?

    tool_class = TOOL_CLASSES[conversion.tool_name]
    unless tool_class
      conversion.update!(status: :failed, error_message: "Unknown tool.")
      return
    end

    tool_class.new(conversion).call
  end
end
