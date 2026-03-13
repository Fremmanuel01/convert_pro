class Users::FirebaseAuthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    id_token = params[:token]

    unless id_token.present?
      return redirect_to new_user_session_path, alert: "No token provided."
    end

    begin
      decoded_token = FirebaseTokenVerifier.verify(id_token)

      if decoded_token.nil?
        return redirect_to new_user_session_path, alert: "Google sign-in failed. Please try again."
      end

      email = decoded_token['email']
      uid   = decoded_token['sub']
      name  = decoded_token['name'] || email.split('@').first

      Rails.logger.info "Authenticating Firebase user. UID: #{uid}, Name: #{name}"

      user = User.find_or_initialize_by(email: email)

      if user.new_record?
        user.password = Devise.friendly_token[0, 20]
        user.save!
      end

      sign_in(user)

      redirect_to stored_location_for(user) || root_path, notice: "Signed in successfully."

    rescue => e
      Rails.logger.error "Firebase Auth Error: #{e.message}"
      redirect_to new_user_session_path, alert: "Google sign-in failed. Please try again."
    end
  end
end
