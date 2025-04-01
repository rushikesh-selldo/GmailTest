require "google/apis/gmail_v1"
require "googleauth"

class GmailService
  def initialize(user)
    @user = user
    @service = Google::Apis::GmailV1::GmailService.new
    @service.authorization = authorize
  end

  # ✅ Get User Emails
  def fetch_emails
    response = @service.list_user_messages("me", max_results: 10) # Fetch latest 10 emails
    emails = response.messages || []

    emails.map do |message|
      @service.get_user_message("me", message.id)
    end
  end

  private

  # ✅ Authorize User with OAuth Token
  def authorize
    return nil if @user.token.blank?

    credentials = Signet::OAuth2::Client.new(
      client_id: ENV["GOOGLE_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CLIENT_SECRET"],
      access_token: @user.token,
      refresh_token: @user.refresh_token,
      token_credential_uri: "https://oauth2.googleapis.com/token"
    )

    if credentials.expired?
      credentials.refresh!
      @user.update(token: credentials.access_token)
    end

    credentials
  end
end
