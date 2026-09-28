class ConversionsController < ApplicationController
  before_action :authenticate_user!, only: [:index]

  def index
    @conversions = current_user.conversions.order(created_at: :desc)
  end

  def show
    @conversion = authorized_conversion(params[:id])
    return redirect_to root_path, alert: "Not authorized to view this conversion." if @conversion.nil?

    # Claim flow: a signed-in user adopting the guest conversion they just made.
    if params[:claim] == "true" && user_signed_in? && @conversion.user_id.nil?
      limiter = ConversionLimiter.new(current_user)
      if limiter.claim!
        @conversion.update(user: current_user, usage_counted: current_user.free?)
        clear_guest_conversion(@conversion.id)
        ConversionMailer.with(user: current_user, conversion: @conversion).result_email.deliver_later
        @auto_download = true
        flash.now[:notice] = "Welcome! Your conversion was successful and is downloading now."
      else
        track_event(:quota_reached, tool_id: tool_id_for(@conversion), properties: { source: "claim" })
        return redirect_to upgrade_billing_path, alert: limiter.status_message
      end
    end

    @tool_meta = ToolRegistry.tools.find { |t| t[:class_name] == @conversion.tool_name }
    @recommendations = ToolRecommender.for(@conversion)
  end

  # Polled by the processing screen (Turbo Frame) to transition Uploading →
  # Processing → Ready in place, with no full-page reload. Ownership-checked
  # exactly like #show, so it can't leak another user's conversion.
  def status
    @conversion = authorized_conversion(params[:id])
    return head :not_found if @conversion.nil?

    @tool_meta = ToolRegistry.tools.find { |t| t[:class_name] == @conversion.tool_name }
    @recommendations = ToolRecommender.for(@conversion)
    render partial: "conversions/status",
           locals: { conversion: @conversion, tool_meta: @tool_meta, recommendations: @recommendations },
           layout: false
  end

  def download
    @conversion = Conversion.find_by(id: params[:id])
    return redirect_to root_path, alert: "Conversion not found." if @conversion.nil?

    # Owned by a user: only that user may download.
    if @conversion.user_id.present?
      return redirect_to root_path, alert: "Not authorized." unless current_user&.id == @conversion.user_id
    else
      # Unassigned (guest) conversion: must be owned by this browser session.
      return redirect_to root_path, alert: "Not authorized." unless guest_owns_conversion?(@conversion.id)

      unless user_signed_in?
        store_location_for(:user, conversion_path(@conversion, claim: true))
        return redirect_to new_user_registration_path,
          notice: "Please create an account to download your file. You get 5 free conversions!"
      end

      limiter = ConversionLimiter.new(current_user)
      if limiter.claim!
        @conversion.update(user: current_user, usage_counted: current_user.free?)
        clear_guest_conversion(@conversion.id)
        ConversionMailer.with(user: current_user, conversion: @conversion).result_email.deliver_later
      else
        track_event(:quota_reached, tool_id: tool_id_for(@conversion), properties: { source: "download" })
        return redirect_to upgrade_billing_path, alert: limiter.status_message
      end
    end

    unless @conversion.output_file.attached?
      return redirect_to conversion_path(@conversion), alert: "File is not ready for download yet."
    end

    track_event(:result_downloaded, tool_id: tool_id_for(@conversion),
                properties: { result_kind: File.extname(@conversion.output_file.blob.filename.to_s).delete(".") })
    deliver_output(@conversion.output_file.blob)
  rescue => e
    Rails.logger.error "Download failed for conversion #{@conversion&.id}: #{e.message}"
    redirect_to conversion_path(@conversion), alert: "Download failed — please try again."
  end

  # Server-authoritative usage accounting for CLIENT-SIDE conversions.
  #
  # The browser calls this BEFORE running an in-browser conversion. It atomically
  # consumes one quota unit and is idempotent per client operation id, so repeated
  # or replayed posts never double-charge. CSRF protection (inherited) blocks
  # cross-origin replay. If the caller is over quota it is refused with 402 and
  # the browser must not proceed.
  def log
    tool = ToolRegistry.find(params[:tool_id])
    return render(json: { error: "unknown_tool" }, status: :not_found) unless tool

    op_id = params[:operation_id].to_s.presence

    # Idempotency: an operation we've already accounted for is simply acknowledged.
    if op_id && (existing = Conversion.find_by(client_operation_id: op_id))
      return render(json: { ok: true, already_counted: true, conversion_id: existing.id })
    end

    limiter = ConversionLimiter.new(current_user)
    unless limiter.claim!
      track_event(:quota_reached, tool_id: tool[:id], properties: { source: "client" })
      return render(json: { ok: false, error: "quota_reached", upgrade_url: upgrade_billing_path },
                    status: :payment_required)
    end

    conversion = Conversion.create!(
      user: current_user,
      tool_name: tool[:class_name],
      status: :completed,
      client_operation_id: op_id,
      usage_counted: current_user&.free? || false
    )

    unless current_user
      session[:guest_conversion_ids] ||= []
      session[:guest_conversion_ids] << conversion.id
    end

    track_event(:conversion_started,   tool_id: tool[:id], properties: { path: "client" })
    track_event(:conversion_succeeded, tool_id: tool[:id], properties: { path: "client" })

    render json: { ok: true, conversion_id: conversion.id }
  rescue ActiveRecord::RecordNotUnique
    # Concurrent duplicate for the same operation id — treat as already counted.
    render json: { ok: true, already_counted: true }
  end

  private

  # Returns the conversion only if the requester is authorized to see it, else nil.
  # Prevents IDOR: a signed-in user can never read another user's conversion by id.
  def authorized_conversion(id)
    conversion = Conversion.find_by(id: id)
    return nil if conversion.nil?

    if conversion.user_id.present?
      (user_signed_in? && conversion.user_id == current_user.id) ? conversion : nil
    else
      guest_owns_conversion?(conversion.id) ? conversion : nil
    end
  end

  def deliver_output(blob)
    safe_filename = clean_download_filename(blob.filename.to_s)

    case blob.service_name
    when "amazon"
      redirect_to blob.url(
        expires_in:   10.minutes,
        disposition:  "attachment; filename=\"#{safe_filename}\"",
        content_type: blob.content_type.presence || "application/octet-stream"
      ), allow_other_host: true
    when "cloudinary"
      cloudinary_url = build_cloudinary_download_url(blob.key, safe_filename)
      raise "Cloudinary resource not found for key: #{blob.key}" unless cloudinary_url
      redirect_to cloudinary_url, allow_other_host: true
    else
      redirect_to rails_blob_path(blob, disposition: "attachment", filename: safe_filename)
    end
  end

  def tool_id_for(conversion)
    ToolRegistry.tools.find { |t| t[:class_name] == conversion.tool_name }&.dig(:id)
  end

  def guest_owns_conversion?(id)
    session[:guest_conversion_ids]&.include?(id)
  end

  def clear_guest_conversion(id)
    session[:guest_conversion_ids]&.delete(id)
  end

  # Returns a browser-safe filename with a guaranteed extension.
  def clean_download_filename(raw)
    name = raw.presence || "converted_output"
    ext  = File.extname(name)
    ext  = ".pdf" if ext.blank?
    base = File.basename(name, ext)
              .gsub(/[^\w\-]/, "_")
              .squeeze("_")
              .delete_prefix("_")
              .truncate(60, omission: "")
    "#{base}#{ext}"
  end

  def build_cloudinary_download_url(key, filename)
    ["raw", "image"].each do |resource_type|
      begin
        Cloudinary::Api.resource(key, resource_type: resource_type)
        return Cloudinary::Utils.cloudinary_url(
          key,
          resource_type: resource_type,
          type:          "upload",
          secure:        true,
          sign_url:      true,
          flags:         "attachment:#{filename.gsub(' ', '_')}"
        )
      rescue Cloudinary::Api::NotFound
        next
      rescue => e
        Rails.logger.warn "Cloudinary lookup (#{resource_type}) failed for #{key}: #{e.message}"
        next
      end
    end
    nil
  end
end
