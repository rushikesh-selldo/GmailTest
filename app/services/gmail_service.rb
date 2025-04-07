# require "google/apis/gmail_v1"
# require "googleauth"
# require "mail"
# require "base64"

# class GmailService
#   def initialize(user)
#     @user = user
#     @service = Google::Apis::GmailV1::GmailService.new
#     @service.authorization = authorize
#   end

#   # Fetch latest emails (max 10)
#   def fetch_emails
#     response = @service.list_user_messages("me", max_results: 10)
#     emails = response.messages || []

#     emails.map do |message|
#       @service.get_user_message("me", message.id)
#     end
#   rescue Google::Apis::Error => e
#     Rails.logger.error "Error fetching emails: #{e.message}"
#     []
#   end

#   # Send an email
#   def send_email(to, subject, body)
#     message = create_mail_message(to, subject, body)
#     raw_message = Base64.urlsafe_encode64(message.to_s)

#     email_object = Google::Apis::GmailV1::Message.new(raw: raw_message)
#     binding.pry
#     @service.send_user_message("me", email_object)
#   rescue Google::Apis::Error => e
#     Rails.logger.error "Error sending email: #{e.message}"
#     raise "Failed to send email"
#   end

#   private

#   # Create an email message using Mail gem


#   def create_mail_message(to, subject, body)
#     user_email = @user.email

#     mail = Mail.new do
#       from    user_email
#       to      to
#       subject subject
#       body    body
#     end
#     binding.pry

#     mail
#   end

#   # Google OAuth Authorization
#   def authorize
#     if @user.token.blank?
#       Rails.logger.error "Authorization failed: Missing access token"
#       return nil
#     end

#     credentials = Signet::OAuth2::Client.new(
#       client_id: ENV["GOOGLE_CLIENT_ID"],
#       client_secret: ENV["GOOGLE_CLIENT_SECRET"],
#       access_token: @user.token,
#       refresh_token: @user.refresh_token,
#       token_credential_uri: "https://oauth2.googleapis.com/token"
#     )

#     if credentials.expired?
#       credentials.refresh!
#       @user.update(token: credentials.access_token)
#     end

#     credentials
#   rescue StandardError => e
#     Rails.logger.error "Authorization error: #{e.message}"
#     nil
#   end
# end
require "google/apis/gmail_v1"
require "mail"

class GmailService
  def initialize(user)
    @user = user
    @service = Google::Apis::GmailV1::GmailService.new
    @service.authorization = fetch_credentials
  end

  def send_email(to, subject, body)
    from_email = @user.email
    to_email = to.to_s.strip

    # Validation: Ensure 'to' is not blank
    if to_email.empty?
      Rails.logger.error "GmailService: 'to' email address is blank."
      raise "Recipient email address is required."
    end

    begin
      mail = Mail.new do
        from    from_email
        to      to_email
        subject subject

        text_part do
          body body
        end

        html_part do
          content_type "text/html; charset=UTF-8"
          body "<html><body>#{body}</body></html>"
        end
      end

      # No Base64 encoding needed
      message = Google::Apis::GmailV1::Message.new(raw: mail.to_s)

      Rails.logger.info "GmailService: Sending email to #{to_email}"
      @service.send_user_message("me", message)
      Rails.logger.info "GmailService: Email successfully sent to #{to_email}"

    rescue Google::Apis::ClientError => e
      Rails.logger.error "GmailService: Gmail API error - #{e.message}"
      raise "Failed to send email: #{e.message}"

    rescue Mail::Field::ParseError => e
      Rails.logger.error "GmailService: Mail gem Parse error - #{e.message}"
      raise "Mail formatting error: #{e.message}"

    rescue => e
      Rails.logger.error "GmailService: Unexpected error - #{e.message}"
      raise "Failed to send email: #{e.message}"
    end
  end

  def fetch_emails
    response = @service.list_user_messages("me", max_results: 10) # Fetch latest 10 emails
    emails = response.messages || []

    emails.map do |message|
      @service.get_user_message("me", message.id)
    end
  end

  def get_email(email_id)
    @service.get_user_message("me", email_id)
  end

  private

  def fetch_credentials
    if @user.token.blank?
      Rails.logger.error "GmailService: No token available for user."
      return nil
    end

    credentials = Signet::OAuth2::Client.new(
      client_id: ENV["GOOGLE_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CLIENT_SECRET"],
      token_credential_uri: "https://oauth2.googleapis.com/token",
      access_token: @user.token,
      refresh_token: @user.refresh_token
    )

    if credentials.expired?
      begin
        credentials.refresh!
        @user.update(token: credentials.access_token)
        Rails.logger.info "GmailService: Token refreshed successfully."
      rescue => e
        Rails.logger.error "GmailService: Error refreshing token - #{e.message}"
        return nil
      end
    end

    credentials
  rescue => e
    Rails.logger.error "GmailService: Error fetching credentials - #{e.message}"
    nil
  end
end
