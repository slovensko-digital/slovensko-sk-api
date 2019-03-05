# Be sure to restart your server when you modify this file.

return unless UpvsEnvironment.sso_support?

Rails.application.config.middleware.use OmniAuth::Builder do
  configure do |config|
    config.logger = Rails.logger
  end

  # Responds to paths:
  # /auth/saml
  # /auth/saml/callback
  # /auth/saml/metadata
  # /auth/saml/slo
  # /auth/saml/spslo

  provider :saml, UpvsEnvironment.sso_settings
end
