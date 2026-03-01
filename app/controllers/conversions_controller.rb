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

    # For active storage services like Cloudinary, we want to force the browser to prompt a download.
    # We can do this by redirecting to the URL directly with the attachment disposition.
    redirect_to @conversion.output_file.url(disposition: "attachment"), allow_other_host: true
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
