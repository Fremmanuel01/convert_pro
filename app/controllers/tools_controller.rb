class ToolsController < ApplicationController
  def index
    @categories = ToolRegistry.categories
  end

  def show
    @tool = ToolRegistry.find(params[:tool_id])
    if @tool.nil?
      redirect_to tools_path, alert: "Tool not found."
    end
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
        :doc_type, :page_count
      ).to_h
      runner = ToolRunner.new(current_user, @tool[:id], params[:files], options)
      conversion = runner.run!
      
      if current_user.nil?
        session[:guest_conversion_ids] ||= []
        session[:guest_conversion_ids] << conversion.id
      end

      redirect_to conversion_path(conversion), notice: "Your files are being processed!"
    rescue ToolRunner::InvalidRequestError => e
      redirect_to tool_path(@tool[:id]), alert: e.message
    rescue ToolRunner::LimitExceededError => e
      redirect_to upgrade_billing_path, alert: e.message
    rescue => e
      Rails.logger.error("ToolsController Error: #{e.message}")
      redirect_to tool_path(@tool[:id]), alert: "An unexpected error occurred."
    end
  end
end
