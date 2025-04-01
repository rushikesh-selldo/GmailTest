
# class EmailsController < ApplicationController
#   # Skip CSRF check for webhooks
#   skip_before_action :verify_authenticity_token, only: [ :webhook ]

#   def index
#     # Fetch and display the latest emails
#     @emails = GmailService.new(current_user).fetch_emails
#   end

#   def webhook
#     Rails.logger.info "Received webhook params: #{params.to_json}"  # Log full params

#     permitted_params = params.permit!
#     Rails.logger.info "Permitted params: #{permitted_params.to_json}"

#     # Verify the authenticity of the request
#     if verify_google_pubsub_request(request)
#       process_email_notification(params)
#       render json: { status: "success" }, status: :ok
#     else
#       render json: { error: "Unauthorized" }, status: :unauthorized
#     end
#   end


#   private

#   # Method to verify if the request is coming from Google
#   def verify_google_pubsub_request(request)
#     # You can implement JWT or other signature verification here
#     # For now, return true as a placeholder for verification
#     true  # Implement JWT verification later if needed
#   end

#   # Process the email notification
#   def process_email_notification(params)
#     # Log the entire incoming payload
#     Rails.logger.info "Processing webhook: #{params.to_json}"

#     # Check if message data is in the expected structure
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
# end
class EmailsController < ApplicationController
     skip_before_action :verify_authenticity_token, only: [ :webhook ]
  #  before_action :authenticate_user!, only: [ :send_email ]



  def index
    @emails = GmailService.new(current_user).fetch_emails
  end



  def webhook
    Rails.logger.info "Received webhook params: #{params.to_json}"

    permitted_params = params.permit!
    Rails.logger.info "Permitted params: #{permitted_params.to_json}"

    if verify_google_pubsub_request(request)
      process_email_notification(params)
      render json: { status: "success" }, status: :ok
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  private

  def verify_google_pubsub_request(request)
    true  # Implement JWT verification later if needed
  end

  def process_email_notification(params)
    Rails.logger.info "Processing webhook: #{params.to_json}"
    message_data = params.dig(:email, :message) || params[:message] || params[:test]

    if message_data.blank?
      Rails.logger.error "No message data received"
      return
    end

    email_id = message_data[:data] || message_data

    if email_id.blank?
      Rails.logger.error "No 'data' field in message"
      return
    end

    begin
      decoded_email_id = Base64.decode64(email_id)
      Rails.logger.info "Decoded Email ID: #{decoded_email_id}"
    rescue => e
      Rails.logger.error "Failed to decode Base64: #{e.message}"
      return
    end

    if decoded_email_id.present?
      ActionCable.server.broadcast("email_notifications", { message: decoded_email_id })
      Rails.logger.info "Broadcasted message: #{decoded_email_id}"
    else
      Rails.logger.error "Skipping broadcast: Decoded email ID is empty or nil"
    end
  end

  def authenticate_user!
    if current_user.nil?
      redirect_to new_email_path, alert: "You must be logged in to send an email."
    end
  end
end
