
# class EmailsController < ApplicationController
#   #  skip_before_action :verify_authenticity_token, only: [ :webhook ]
#   #  before_action :authenticate_user!, only: [ :send_email ]

#   before_action :authenticate_user! # Ensure user is logged in


#   skip_before_action :verify_authenticity_token, only: [ :send_email ]




#   def index
#     @emails = GmailService.new(current_user).fetch_emails
#   end
#   def show
#     email = find_email(params[:id])

#     if email
#       content = email.payload.parts&.first&.body&.data || email.snippet
#       render json: {
#         subject: email.payload.headers.find { |h| h.name == "Subject" }&.value,
#         from: email.payload.headers.find { |h| h.name == "From" }&.value,
#         body: content
#       }
#     else
#       render json: { error: "Email not found" }, status: 404
#     end
#   end


#   def new
#   end

#   def send_email
#     recipient = params[:to]
#     subject = params[:subject]
#     body = params[:body]

#     if recipient.blank? || subject.blank? || body.blank?
#       flash[:error] = "All fields are required."
#       redirect_to new_email_path and return
#     end

#     begin
#       GmailService.new(current_user).send_email(recipient, subject, body)
#       flash[:success] = "Email sent successfully!"
#     rescue => e
#       Rails.logger.error "Failed to send email: #{e.message}"
#       flash[:error] = "Failed to send email."
#     end

#     redirect_to new_email_path
#   end

#   def webhook
#     Rails.logger.info "Received webhook params: #{params.to_json}"

#     permitted_params = params.permit!
#     Rails.logger.info "Permitted params: #{permitted_params.to_json}"

#     if verify_google_pubsub_request(request)
#       process_email_notification(params)
#       render json: { status: "success" }, status: :ok
#     else
#       render json: { error: "Unauthorized" }, status: :unauthorized
#     end
#   end

#   private

#   def verify_google_pubsub_request(request)
#     true
#   end


#   def find_email(email_id)
#     client = Google::Apis::GmailV1::GmailService.new
#     client.authorization = user_google_credentials
#     client.get_user_message("me", email_id)
#   end

#   def user_google_credentials
#     user = current_user
#     Signet::OAuth2::Client.new(
#       client_id: ENV["GOOGLE_CLIENT_ID"],
#       client_secret: ENV["GOOGLE_CLIENT_SECRET"],
#       token_credential_uri: "https://oauth2.googleapis.com/token",
#       access_token: user.token,
#       refresh_token: user.refresh_token
#     )
#   end


#   def process_email_notification(params)
#     Rails.logger.info "Processing webhook: #{params.to_json}"
#     message_data = params.dig(:email, :message) || params[:message] || params[:test]

#     if message_data.blank?
#       Rails.logger.error "No message data received"
#       return
#     end

#     email_id = message_data[:data] || message_data

#     if email_id.blank?
#       Rails.logger.error "No 'data' field in message"
#       return
#     end

#     begin
#       decoded_email_id = Base64.decode64(email_id)
#       Rails.logger.info "Decoded Email ID: #{decoded_email_id}"
#     rescue => e
#       Rails.logger.error "Failed to decode Base64: #{e.message}"
#       return
#     end

#     if decoded_email_id.present?
#       ActionCable.server.broadcast("email_notifications", { message: decoded_email_id })
#       Rails.logger.info "Broadcasted message: #{decoded_email_id}"
#     else
#       Rails.logger.error "Skipping broadcast: Decoded email ID is empty or nil"
#     end
#   end


#   def authenticate_user!
#     if current_user.nil?
#       redirect_to new_email_path, alert: "You must be logged in to send an email."
#     end
#   end
# end
#


class EmailsController < ApplicationController
  before_action :authenticate_user!, only: [ :send_email, :index, :show ]
  skip_before_action :verify_authenticity_token, only: [ :send_email ]

  def index
    @emails = GmailService.new(current_user).fetch_emails
  end

  def show
    email = GmailService.new(current_user).get_email(params[:id])
    if email
      content = email.payload.parts&.first&.body&.data || email.snippet
      render json: {
        subject: header_value(email, "Subject"),
        from: header_value(email, "From"),
        body: content
      }
    else
      render json: { error: "Email not found" }, status: 404
    end
  end

  def new
  end

  def send_email
    to = params[:to]
    subject = params[:subject]
    body = params[:body]

    if to.blank? || subject.blank? || body.blank?
      redirect_to new_email_path, alert: "All fields are required."
      return
    end

    begin
      GmailService.new(current_user).send_email(to, subject, body)
      redirect_to emails_path, notice: "Email sent successfully!"
    rescue => e
      Rails.logger.error "Failed to send email: #{e.message}"
      redirect_to new_email_path, alert: "Failed to send email: #{e.message}"
    end
  end

  def webhook
    Rails.logger.info "Received webhook params: #{params.to_json}"
    permitted_params = params.permit!

    if verify_google_pubsub_request(request)
      process_email_notification(permitted_params)
      render json: { status: "success" }, status: :ok
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  private

  def authenticate_user!
    if current_user.nil?
      flash[:error] = "You must be logged in to access this page."
      redirect_to new_email_path
    end
  end

  def header_value(email, header_name)
    email.payload.headers.find { |h| h.name == header_name }&.value
  end

  def verify_google_pubsub_request(request)
    true
  end

  def process_email_notification(params)
    message_data = params.dig(:email, :message) || params[:message] || params[:test]
    if message_data.blank?
      Rails.logger.error "No message data received"
      return
    end

    email_id_encoded = message_data[:data] || message_data
    decoded_id = Base64.decode64(email_id_encoded) rescue nil

    if decoded_id.present?
      ActionCable.server.broadcast("email_notifications", { message: decoded_id })
      Rails.logger.info "Broadcasted message: #{decoded_id}"
    else
      Rails.logger.error "Decoded email ID is empty or invalid"
    end
  end
end
