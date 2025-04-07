Rails.application.routes.draw do
  # Root path
  root "home#index"

  get "auth/:provider/callback", to: "sessions#google_auth"
  get "auth/failure", to: redirect("/")
  delete "logout", to: "sessions#destroy"
  get "emails", to: "emails#index"
  post "/emails/webhook", to: "emails#webhook"
  post "/send_email", to: "emails#send_email", as: :send_email
  get "/send_email/new", to: "emails#new", as: :new_email
  get "/emails/:id", to: "emails#show"
end
