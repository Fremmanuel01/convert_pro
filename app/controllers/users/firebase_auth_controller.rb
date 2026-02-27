class Users::FirebaseAuthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  
  def create
    id_token = params[:token]
    
    unless id_token.present?
      return render json: { error: "No token provided" }, status: :bad_request
    end

    begin
      # Verify the token against Google's public keys using our custom Rails.cache backed verifier
      decoded_token = FirebaseTokenVerifier.verify(id_token)
      
      if decoded_token.nil?
        return render json: { error: "Invalid token" }, status: :unauthorized
      end
      
      # The payload looks like: {"email"=>"user@example.com", "uid"=>"firebase_uid", "email_verified"=>true}
      email = decoded_token['email']
      uid = decoded_token['sub'] # 'sub' is the unique user ID in Firebase
      name = decoded_token['name'] || email.split('@').first
      
      Rails.logger.info "Authenticating Firebase user. UID: #{uid}, Name: #{name}"
      
      # Find or create user
      user = User.find_or_initialize_by(email: email)
      
      if user.new_record?
        # Set a very secure random password since they will solely log in via Google
        user.password = Devise.friendly_token[0, 20]
        # user.uid = uid # Uncomment if we added a `uid` column to users
        user.save!
      end
      
      # Sign in via Devise
      sign_in(user)
      
      redirect_path = stored_location_for(user) || root_path
      render json: { success: true, redirect_url: redirect_path }
      
    rescue => e
      Rails.logger.error "Firebase Auth Error: #{e.message}"
      render json: { error: "Authentication failed" }, status: :internal_server_error
    end
  end
end
