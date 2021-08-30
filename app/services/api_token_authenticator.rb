# See https://tools.ietf.org/html/rfc7519

class ApiTokenAuthenticator
  MAX_EXP_IN = 5.minutes
  JTI_PATTERN = /\A[0-9a-z\-_]{32,256}\z/i

  def initialize(identifier_store:, public_key:, subject_verifier:, obo_token_authenticator:)
    @identifier_store = identifier_store
    @public_key = public_key
    @subject_verifier = subject_verifier
    @obo_token_authenticator = obo_token_authenticator
  end

  def invalidate_token(token, allow_plain: false, allow_sub: false, allow_obo_token: false)
    verify_token(token, allow_plain: allow_plain, allow_sub: allow_sub, allow_obo_token: allow_obo_token) do |payload, header|
      @obo_token_authenticator.invalidate_token(payload['obo']) if header['cty'] && payload['obo']
    end
  end

  def verify_token(token, allow_plain: false, allow_sub: false, allow_obo_token: false, require_obo_token_scope: nil)
    raise ArgumentError if !allow_plain && !allow_sub && !allow_obo_token
    raise ArgumentError if !allow_obo_token && require_obo_token_scope

    options = {
      algorithm: 'RS256',
      verify_expiration: false,
      verify_not_before: false,
      verify_jti: -> (jti) { jti =~ JTI_PATTERN },
    }

    payload, header = JWT.decode(token, @public_key, true, options)
    cty, sub, obo = header['cty'], payload['sub'], payload['obo']

    if cty && obo
      raise JWT::DecodeError unless obo_token_support?
      raise JWT::InvalidPayload unless allow_obo_token
      raise JWT::InvalidPayload if cty != 'JWT'
      raise JWT::InvalidPayload if sub

      begin
        sub, obo = @obo_token_authenticator.verify_token(obo, scope: require_obo_token_scope)
      rescue JWT::DecodeError
        raise JWT::InvalidPayload, :obo
      end

      raise JWT::InvalidSubError, :obo unless sub
    # elsif sub && obo
    #   raise JWT::InvalidPayload unless allow_obo_id
    #   raise JWT::InvalidPayload if cty
    #
    #   # TODO verify OBO id here
    elsif sub
      raise JWT::InvalidPayload unless allow_sub
      raise JWT::InvalidPayload if cty
      raise JWT::InvalidPayload if obo
    else
      raise allow_sub ? JWT::InvalidSubError : JWT::InvalidPayload unless allow_plain
      raise JWT::InvalidPayload if cty
      raise JWT::InvalidPayload if obo
    end

    exp, jti = payload['exp'], payload['jti']

    raise JWT::InvalidSubError, (obo ? :obo : nil) if sub && !@subject_verifier.call(sub)
    raise JWT::InvalidPayload, :exp unless exp.is_a?(Integer)

    now = Time.now.to_f

    raise JWT::ExpiredSignature, :exp if exp <= now
    raise JWT::InvalidPayload, :exp if exp > (now + MAX_EXP_IN)
    raise JWT::InvalidJtiError unless @identifier_store.write([sub, jti], true, expires_in: MAX_EXP_IN, unless_exist: true)

    return yield payload, header if block_given?

    [sub, obo]
  end

  private

  def obo_token_support?
    !!@obo_token_authenticator
  end
end
