module Environment
  extend self

  def login_callback_urls
    @login_callback_urls ||= ENV.fetch('LOGIN_CALLBACK_URLS').split(',')
  end

  def logout_callback_urls
    @logout_callback_urls ||= ENV.fetch('LOGOUT_CALLBACK_URLS').split(',')
  end

  def api_token_authenticator
    @api_token_authenticator ||= ApiTokenAuthenticator.new(
      identifier_store: api_token_identifier_store,
      public_key: OpenSSL::PKey::RSA.new(File.read(ENV.fetch('API_TOKEN_PUBLIC_KEY_FILE'))),
      obo_token_authenticator: UpvsEnvironment.sso_support? ? obo_token_authenticator : nil,
    )
  end

  def api_token_identifier_store
    @api_token_identifier_store ||= ActiveSupport::Cache::RedisCacheStore.new(
      namespace: 'api-token-identifiers',
      error_handler: REDIS_CONNECTION_ENFORCER,
      compress: false,
    )
  end

  def obo_token_authenticator
    @obo_token_authenticator ||= OboTokenAuthenticator.new(
      assertion_store: obo_token_assertion_store,
      key_pair: OpenSSL::PKey::RSA.new(File.read(ENV.fetch('OBO_TOKEN_PRIVATE_KEY_FILE')))
    )
  end

  def obo_token_assertion_store
    @obo_token_assertion_store ||= ActiveSupport::Cache::RedisCacheStore.new(
      namespace: 'obo-token-assertions',
      error_handler: REDIS_CONNECTION_ENFORCER,
      compress: true,
    )
  end

  # RedisCacheStore ignores standard errors
  RedisConnectionError = Class.new(Exception)

  REDIS_CONNECTION_ENFORCER = -> (*) { raise RedisConnectionError }
end
