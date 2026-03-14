class ConversionsController < ApplicationController
  before_action :authenticate_user!, only: [:index]

  def index
    @conversions = current_user.conversions.order(created_at: :desc)
  end

  def show
    if user_signed_in?
      @conversion = current_user.conversions.find_by(id: params[:id])
    end
    
    # Allow guests to view if in session
    @conversion ||= Conversion.find_by(id: params[:id])

    if @conversion.nil? || (@conversion.user_id.nil? && !guest_owns_conversion?(@conversion.id))
      return redirect_to root_path, alert: "Not authorized to view this conversion."
    end

    # Handle claim flow (post sign-up/sign-in auto-download)
    if params[:claim] == 'true' && user_signed_in? && @conversion.user_id.nil? && guest_owns_conversion?(@conversion.id)
      limiter = ConversionLimiter.new(current_user)
      if limiter.can_convert?
        @conversion.update(user: current_user)
        limiter.increment! # Count this guest conversion against the user's limit
        clear_guest_conversion(@conversion.id)
        
        # Send result email
        ConversionMailer.with(user: current_user, conversion: @conversion).result_email.deliver_later
        
        # Trigger auto-download on the view
        @auto_download = true
        flash.now[:notice] = "Welcome! Your conversion was successful and is downloading now."
      else
        return redirect_to upgrade_billing_path, alert: limiter.status_message
      end
    end

    @tool_meta = ToolRegistry.tools.find { |t| t[:class_name] == @conversion.tool_name }
  end

  def download
    @conversion = Conversion.find_by(id: params[:id])
    
    if @conversion.nil?
      return redirect_to root_path, alert: "Conversion not found."
    end
    
    # If the file belongs to a user, but someone isn't signed in or isn't that user
    if @conversion.user_id.present? && current_user&.id != @conversion.user_id
      return redirect_to root_path, alert: "Not authorized."
    end

    # If it's a guest conversion
    if @conversion.user_id.nil?
      unless guest_owns_conversion?(@conversion.id)
        return redirect_to root_path, alert: "Not authorized."
      end

      # Force sign in/up to download
      unless user_signed_in?
        # Store the show page with claim param instead of the direct download
        store_location_for(:user, conversion_path(@conversion, claim: true))
        return redirect_to new_user_registration_path, notice: "Please create an account to download your file. You get 5 free conversions!"
      end

      # User is signed in, associate conversion
      limiter = ConversionLimiter.new(current_user)
      if limiter.can_convert?
        @conversion.update(user: current_user)
        limiter.increment! # Count this guest conversion against the user's limit
        clear_guest_conversion(@conversion.id)
        # Send result email for users who just sign in directly and click download
        ConversionMailer.with(user: current_user, conversion: @conversion).result_email.deliver_later
      else
        return redirect_to upgrade_billing_path, alert: limiter.status_message
      end
    end

    unless @conversion.output_file.attached?
      return redirect_to conversion_path(@conversion), alert: "File is not ready for download yet."
    end

    blob     = @conversion.output_file.blob
    filename = blob.filename.to_s
    # Ensure the filename has an extension so the browser knows the file type
    if File.extname(filename).blank?
      filename += ".pdf"
    end
    content_type = blob.content_type.presence || "application/octet-stream"

    # Stream the file bytes through Rails with explicit Content-Disposition so
    # the browser always prompts a download with the correct filename/extension,
    # regardless of where the file is stored (local disk, Cloudinary, etc.).
    begin
      file_data = blob.download
      send_data file_data,
        filename:    filename,
        type:        content_type,
        disposition: "attachment"
    rescue => e
      Rails.logger.error "Download stream failed for conversion #{@conversion.id}: #{e.message}"
      redirect_to conversion_path(@conversion), alert: "Download failed — please try again."
    end
  end

  def log
    tool = ToolRegistry.find(params[:tool_id])
    return head :not_found unless tool

    conversion = Conversion.create!(
      user: current_user,
      tool_name: tool[:class_name],
      status: :completed
    )

    if current_user
      ConversionLimiter.new(current_user).increment!
    else
      session[:guest_conversion_ids] ||= []
      session[:guest_conversion_ids] << conversion.id
    end

    head :ok
  end

  private

  def guest_owns_conversion?(id)
    session[:guest_conversion_ids]&.include?(id)
  end

  def clear_guest_conversion(id)
    session[:guest_conversion_ids]&.delete(id)
  end
end
