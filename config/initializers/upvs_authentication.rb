# Be sure to restart your server when you modify this file.

return unless UpvsEnvironment.sso_support?

Rails.application.config.middleware.use OmniAuth::Builder do
  configure do |config|
    # Raise errors in every environment instead of redirecting to the default error page.
    config.failure_raise_out_environments = ['development', 'production', 'staging', 'test']

    # Respond to saml, saml/callback, saml/metadata, saml/slo, and saml/spslo under path prefix.
    config.path_prefix = '/auth'

    # Use default application logger.
    config.logger = Rails.logger
  end

  provider :saml, UpvsEnvironment.sso_settings
end
