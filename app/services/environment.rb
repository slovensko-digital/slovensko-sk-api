# TODO use ActiveSupport::Cache::Store::RedisStore to maintain persistence

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
      jti_cache: api_token_identifier_cache,
      public_key: OpenSSL::PKey::RSA.new(File.read(ENV.fetch('API_TOKEN_PUBLIC_KEY_FILE'))),
      obo_token_authenticator: obo_token_authenticator,
    )
  end

  def api_token_identifier_cache
    @api_token_identifier_cache ||= ActiveSupport::Cache::MemoryStore.new(
      namespace: 'api-token-identifiers',
      size: 128.megabytes,
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
    @obo_token_assertion_store ||= ActiveSupport::Cache::MemoryStore.new(
      namespace: 'upvs-token-assertions',
      size: 128.megabytes,
      compress: true,
    )
  end
end
