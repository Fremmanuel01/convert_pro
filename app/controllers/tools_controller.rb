class ToolsController < ApplicationController
  CLIENT_SIDE_IDS = %w[images_to_pdf merge_pdf split_pdf unlock_pdf pdf_to_images
                       heic_to_jpg heic_to_png webp_to_jpg webp_to_png].freeze

  def index
    @categories = ToolRegistry.categories
  end

  def show
    @tool = ToolRegistry.find(params[:tool_id])
    if @tool.nil?
      redirect_to tools_path, alert: "Tool not found."
      return
    end

    @handoff = handoff_for(@tool, params[:from_conversion])

    source = %w[home next].include?(params[:from]) ? params[:from] : "direct"
    track_event(:tool_viewed, tool_id: @tool[:id],
                properties: { tool_category: @tool[:category], source: source,
                              path: client_side_path?(@tool[:id]) ? "client" : "server" })
  end

  def create
    @tool = ToolRegistry.find(params[:tool_id])
    return redirect_to tools_path, alert: "Tool not found." unless @tool

    begin
      options = params.permit(
        :url, :password, :language, :rotation,
        :prompt, :watermark, :watermark_position, :opacity, :target_language,
        :page_size, :page_orientation, :fit_mode, :margin,
        :quality, :dpi, :image_format,
        :slide_count, :tone, :audience,
        :doc_type, :page_count,
        :from_page, :to_page
      ).to_h
      files = params[:files]
      source = handoff_for(@tool, params[:from_conversion_id])

      runner = ToolRunner.new(current_user, @tool[:id], files, options, source_conversion_id: source&.dig(:id))
      conversion = runner.run!

      if current_user.nil?
        session[:guest_conversion_ids] ||= []
        session[:guest_conversion_ids] << conversion.id
      end

      track_event(:conversion_started, tool_id: @tool[:id],
                  properties: { path: "server", source: (source ? "handoff" : "upload"),
                                file_count: Array(files).reject(&:blank?).size })

      redirect_to conversion_path(conversion), notice: "Your files are being processed!"
    rescue ToolRunner::InvalidRequestError => e
      redirect_to tool_path(@tool[:id]), alert: e.message
    rescue ToolRunner::LimitExceededError => e
      track_event(:quota_reached, tool_id: @tool[:id], properties: { source: "upload", reason: e.reason })
      redirect_to upgrade_billing_path(reason: e.reason, tool_id: @tool[:id]), alert: e.message
    rescue => e
      Rails.logger.error("ToolsController Error: #{e.message}")
      redirect_to tool_path(@tool[:id]), alert: "An unexpected error occurred."
    end
  end

  private

  # File hand-off: returns {id:, filename:} when `conversion_id` is a completed
  # conversion the requester owns whose OUTPUT type this tool accepts — else nil.
  # Server-side tools only; ownership reuses the same rules as ConversionsController.
  def handoff_for(tool, conversion_id)
    return nil if conversion_id.blank? || client_side_path?(tool[:id]) || tool[:accepted_types].blank?

    conv = Conversion.find_by(id: conversion_id)
    return nil unless conv&.completed? && conv.output_file.attached?
    return nil unless owns_conversion?(conv)

    mime = conv.output_file.blob.content_type
    return nil unless tool[:accepted_types].include?(mime)

    { id: conv.id, filename: conv.output_file.blob.filename.to_s }
  end

  def owns_conversion?(conv)
    if conv.user_id.present?
      user_signed_in? && conv.user_id == current_user.id
    else
      session[:guest_conversion_ids]&.include?(conv.id)
    end
  end

  def client_side_path?(tool_id)
    CLIENT_SIDE_IDS.include?(tool_id)
  end
end
