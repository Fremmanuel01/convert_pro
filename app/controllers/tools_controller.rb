class ToolsController < ApplicationController
  def index
    @categories = ToolRegistry.categories
  end

  def show
    @tool = ToolRegistry.find(params[:tool_id])
    if @tool.nil?
      redirect_to tools_path, alert: "Tool not found."
      return
    end

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
      runner = ToolRunner.new(current_user, @tool[:id], files, options)
      conversion = runner.run!

      if current_user.nil?
        session[:guest_conversion_ids] ||= []
        session[:guest_conversion_ids] << conversion.id
      end

      track_event(:conversion_started, tool_id: @tool[:id],
                  properties: { path: "server", file_count: Array(files).reject(&:blank?).size })

      redirect_to conversion_path(conversion), notice: "Your files are being processed!"
    rescue ToolRunner::InvalidRequestError => e
      redirect_to tool_path(@tool[:id]), alert: e.message
    rescue ToolRunner::LimitExceededError => e
      track_event(:quota_reached, tool_id: @tool[:id], properties: { source: "upload" })
      redirect_to upgrade_billing_path, alert: e.message
    rescue => e
      Rails.logger.error("ToolsController Error: #{e.message}")
      redirect_to tool_path(@tool[:id]), alert: "An unexpected error occurred."
    end
  end

  private

  def client_side_path?(tool_id)
    %w[images_to_pdf merge_pdf split_pdf unlock_pdf pdf_to_images
       heic_to_jpg heic_to_png webp_to_jpg webp_to_png].include?(tool_id)
  end
end
