# See https://tools.ietf.org/html/rfc7519

class ApiTokenAuthenticator
  MAX_EXP_IN = OboTokenAuthenticator::MAX_EXP_IN
  JTI_PATTERN = /^[0-9a-z-_]{1,256}$/

  def initialize(identifier_store:, public_key:, obo_token_authenticator:)
    @identifier_store = identifier_store
    @public_key = public_key
    @obo_token_authenticator = obo_token_authenticator
  end

  def invalidate_token(token, allow_ta: false, allow_obo: false)
    verify_token(token, allow_ta: allow_ta, allow_obo: allow_obo) do |payload, _|
      @obo_token_authenticator.invalidate_token(payload['obo']) if payload['obo']
    end
  end

  def verify_token(token, allow_ta: false, allow_obo: false, require_obo_scope: nil)
    raise ArgumentError if !allow_ta && !allow_obo
    raise ArgumentError if !allow_obo && require_obo_scope

    require_ta = allow_ta && !allow_obo
    require_obo = !allow_ta && allow_obo

    options = {
      algorithm: 'RS256',
      verify_jti: -> (jti) { jti =~ JTI_PATTERN },
    }

    payload, header = JWT.decode(token, @public_key, true, options)

    cty, obo = header['cty'], payload['obo']

    if obo
      raise JWT::DecodeError unless obo_token_support?
      raise JWT::InvalidPayload if require_ta
      raise JWT::InvalidPayload if cty != 'JWT'
    else
      raise JWT::InvalidPayload if require_obo
      raise JWT::InvalidPayload if cty
    end

    exp, jti = payload['exp'], payload['jti']

    raise JWT::ExpiredSignature unless exp.is_a?(Integer)
    raise JWT::InvalidPayload if exp > (Time.now + MAX_EXP_IN).to_i
    raise JWT::InvalidJtiError unless @identifier_store.write(jti, true, expires_in: MAX_EXP_IN, unless_exist: true)

    return yield payload, header if block_given?

    @obo_token_authenticator.verify_token(obo, scope: require_obo_scope) if require_obo || obo
  end

  private

  def obo_token_support?
    !!@obo_token_authenticator
  end
end
