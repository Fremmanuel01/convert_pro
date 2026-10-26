class UserMailer < ApplicationMailer
  # Lifecycle: sent once, right after sign-up. Orients the new user and drives
  # them back to their first conversion.
  def welcome
    @user = params[:user]
    mail(to: @user.email, subject: "Welcome to OfficedocTools")
  end
end
