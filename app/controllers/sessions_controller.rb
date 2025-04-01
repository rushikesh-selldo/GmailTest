
class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :google_auth ]

  def google_auth
    user_info = request.env["omniauth.auth"]

    if user_info.blank?
      Rails.logger.error "Google OAuth response is blank."
      redirect_to root_path, alert: "Authentication failed. Please try again."
      return
    end

    user = User.find_or_initialize_by(email: user_info.info.email)
    user.assign_attributes(
      name: user_info.info.name,
      google_uid: user_info.uid,
      token: user_info.credentials.token,
      refresh_token: user_info.credentials.refresh_token || user.refresh_token,
      image: user_info.info.image
    )

    user.save!
    session[:user_id] = user.id
    redirect_to root_path, notice: "Logged in successfully!"
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Logged out!"
  end
end
