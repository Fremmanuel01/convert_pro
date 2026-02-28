class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Google'
      sign_in_and_redirect @user, event: :authentication
    else
      # If the user validation failed, log why and display it
      Rails.logger.error "OAUTH ERROR: #{@user.errors.full_messages}"
      redirect_to new_user_registration_url, alert: "Google Auth Failed: #{@user.errors.full_messages.join(', ')}"
    end
  end

  def failure
    redirect_to root_path
  end
end
