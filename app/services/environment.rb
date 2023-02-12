module Environment
  extend self

  # TODO move to UpvsEnvironment and rename to #sso_callback_urls, also rename env var to SSO_CALLBACK_URLS as this is only UPVS SSO related configuration
  def login_callback_url
    @login_callback_url ||= ENV.fetch('LOGIN_CALLBACK_URL')
  end

  # TODO move to UpvsEnvironment and rename to #slo_callback_urls, also rename env var to SLO_CALLBACK_URLS as this is only UPVS SSO related configuration
  def logout_callback_url
    @logout_callback_url ||= ENV.fetch('LOGOUT_CALLBACK_URL')
  end

  def api_token_authenticator
    @api_token_authenticator ||= ApiTokenAuthenticator.new(
      identifier_store: api_token_identifier_store,
      public_key: OpenSSL::PKey::RSA.new(File.read(Rails.root.join('security', "api_token_#{Rails.env}.public.pem"))),
      subject_verifier: -> (sub) { UpvsEnvironment.subject?(sub) },
      obo_token_authenticator: obo_token_authenticator,
    )
  end

  def api_token_identifier_store
    @api_token_identifier_store ||= ActiveSupport::Cache::RedisCacheStore.new(
      namespace: 'api-token-identifiers',
      error_handler: REDIS_CONNECTION_ENFORCER,
      compress: false,
      url: ENV['REDIS_URL'] || 'redis://localhost:6379/0'
    )
  end

  def obo_token_authenticator
    @obo_token_authenticator ||= OboTokenAuthenticator.new(
      assertion_store: obo_token_assertion_store,
      key_pair: OpenSSL::PKey::RSA.new(File.read(Rails.root.join('security', "obo_token_#{Rails.env}.private.pem"))),
      proxy_subject: UpvsEnvironment.sso_proxy_subject,
    ) if (UpvsEnvironment.obo_support? || UpvsEnvironment.sso_support?)
  end

  def obo_token_assertion_store
    @obo_token_assertion_store ||= ActiveSupport::Cache::RedisCacheStore.new(
      namespace: 'obo-token-assertions',
      error_handler: REDIS_CONNECTION_ENFORCER,
      compress: true,
      url: ENV['REDIS_URL'] || 'redis://localhost:6379/0'
    ) if (UpvsEnvironment.obo_support? || UpvsEnvironment.sso_support?)
  end

  def obo_token_scopes
    @obo_token_scopes ||= ['sktalk/receive', 'sktalk/receive_and_save_to_outbox', 'sktalk/save_to_outbox', 'sktalk/prepare_for_later_receive', 'upvs/assertion', 'upvs/identity']
  end

  # RedisCacheStore ignores standard errors
  RedisConnectionError = Class.new(Exception)

  REDIS_CONNECTION_ENFORCER = -> (*) { raise RedisConnectionError }
end
