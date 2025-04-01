# Rails.application.config.middleware.use OmniAuth::Builder do
#   provider :google_oauth2,
#            Rails.application.credentials.dig(:google, :client_id),
#            Rails.application.credentials.dig(:google, :client_secret),
#            {
#              scope: "email,profile",
#              prompt: "select_account",
#              access_type: "offline",
#              redirect_uri: "http://localhost:3000/auth/google_oauth2/callback"
#            }
# end

# OmniAuth.config.allowed_request_methods = [ :get, :post ]
# OmniAuth.config.silence_get_warning = true
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           Rails.application.credentials.dig(:google, :client_id),
           Rails.application.credentials.dig(:google, :client_secret),
           {
            scope: "email, profile, https://www.googleapis.com/auth/gmail.readonly,  https://www.googleapis.com/auth/gmail.send",
            prompt: "consent",
             access_type: "offline",
             provider_ignores_state: true,  # 🚨 Disables CSRF protection
             redirect_uri: "http://localhost:3000/auth/google_oauth2/callback"
           }
end

# Allow GET requests for OmniAuth callbacks (fixes CSRF issue)
OmniAuth.config.allowed_request_methods = [ :post, :get ]
OmniAuth.config.silence_get_warning = true
