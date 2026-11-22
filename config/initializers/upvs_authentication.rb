# Be sure to restart your server when you modify this file.

# The block is evaluated when the middleware stack is built, after application code becomes loadable.
Rails.application.config.middleware.use OmniAuth::Builder do
  next unless UpvsEnvironment.sso_support?

  configure do |config|
    # Raise errors in every environment instead of redirecting to the default error page.
    config.failure_raise_out_environments = [ "development", "production", "staging", "test" ]

    # Respond to saml, saml/callback, saml/metadata, saml/slo, and saml/spslo under path prefix.
    config.path_prefix = "/auth"

    # Use default application logger.
    config.logger = Rails.logger

    # Allow request phase via GET since /login redirects to it, CVE-2015-9284 was assessed as not applicable (API-103),
    # POST requests remain protected by authenticity token verification.
    config.allowed_request_methods = [ :get, :post ]
    config.silence_get_warning = true
  end

  provider :saml, UpvsEnvironment.sso_settings
end
