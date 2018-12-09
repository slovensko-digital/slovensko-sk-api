module ApiEnvironment
  extend self

  def login_callback_url
    ENV.fetch('API_LOGIN_CALLBACK_URL')
  end

  def logout_callback_url
    ENV.fetch('API_LOGOUT_CALLBACK_URL')
  end

  # TODO rename to api_token_authenticator
  def token_authenticator
    @token_authenticator ||= TokenWrapper.new(
      token_authenticator: UpvsEnvironment.token_authenticator,
      public_key: OpenSSL::PKey::RSA.new(File.read(ENV.fetch('API_TOKEN_PUBLIC_KEY_FILE'))),
      jti_cache: jti_cache,
    )
  end

  # TODO rename
  def jti_cache
    # TODO use ActiveSupport::Cache::Store::RedisStore to maintain persistence
    @token_identifier_cache ||= ActiveSupport::Cache::MemoryStore.new(
      namespace: 'api-token-identifiers',
      size: 128.megabytes,
      compress: false,
    )
  end
end
