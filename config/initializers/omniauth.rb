
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           Rails.application.credentials.dig(:google, :client_id),
           Rails.application.credentials.dig(:google, :client_secret),
           {
            scope: "email, profile, https://www.googleapis.com/auth/gmail.readonly,  https://www.googleapis.com/auth/gmail.send",
            prompt: "consent",
             access_type: "offline",
             provider_ignores_state: true,
             redirect_uri: "http://localhost:3000/auth/google_oauth2/callback"
           }
end

OmniAuth.config.allowed_request_methods = [ :post, :get ]
OmniAuth.config.silence_get_warning = true
