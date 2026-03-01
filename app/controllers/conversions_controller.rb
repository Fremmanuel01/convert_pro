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
        limiter.increment!
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

      # User is signed in, associate conversion and increment limit
      limiter = ConversionLimiter.new(current_user)
      if limiter.can_convert?
        @conversion.update(user: current_user)
        limiter.increment!
        clear_guest_conversion(@conversion.id)
        # Send result email for users who just sign in directly and click download
        ConversionMailer.with(user: current_user, conversion: @conversion).result_email.deliver_later
      else
        return redirect_to upgrade_billing_path, alert: limiter.status_message
      end
    end

    blob = @conversion.output_file
    
    # Use Cloudinary SDK to build the correct delivery URL with the right resource type
    # This avoids the 401 (wrong resource type) and 404 (wrong path) errors from raw redirects
    begin
      cloudinary_key = blob.key
      # Determine if it's a raw file (PDF, ZIP, DOCX) or image
      mime = blob.content_type.presence || "application/octet-stream"
      resource_type = mime.start_with?("image/") ? "image" : "raw"
      
      url = Cloudinary::Utils.cloudinary_url(cloudinary_key, 
        resource_type: resource_type,
        type: "upload",
        secure: true
      )
      redirect_to url, allow_other_host: true
    rescue => e
      Rails.logger.warn "Cloudinary URL build failed (#{e.message}), falling back to proxy"
      blob.open do |tempfile|
        send_data tempfile.read,
                  filename: blob.filename.to_s,
                  type: blob.content_type.presence || "application/octet-stream",
                  disposition: "attachment"
      end
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

  def clear_guest_conversion?(id)
    session[:guest_conversion_ids]&.delete(id)
  end
  def clear_guest_conversion(id)
    session[:guest_conversion_ids]&.delete(id)
  end
end
