module ApiEnvironment
  extend self

  def login_callback_url
    ENV.fetch('API_LOGIN_CALLBACK_URL')
  end

  def logout_callback_url
    ENV.fetch('API_LOGOUT_CALLBACK_URL')
  end

  def token_authenticator
    @token_authenticator ||= TokenWrapper.new(
      token_authenticator: UpvsEnvironment.token_authenticator,
      public_key: OpenSSL::PKey::RSA.new(File.read(ENV.fetch('API_TOKEN_PUBLIC_KEY_FILE'))),
    )
  end
end
