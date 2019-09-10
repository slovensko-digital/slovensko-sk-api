# See https://tools.ietf.org/html/rfc7519

class ApiTokenAuthenticator
  MAX_EXP_IN = UpvsEnvironment::PROXY_MAX_EXP_IN
  JTI_PATTERN = /\A[0-9a-z\-_]{32,256}\z/i

  def initialize(identifier_store:, public_key:, obo_token_authenticator:)
    @identifier_store = identifier_store
    @public_key = public_key
    @obo_token_authenticator = obo_token_authenticator
  end

  def invalidate_token(token, allow_ta: false, allow_obo: false)
    verify_token(token, allow_ta: allow_ta, allow_obo: allow_obo) do |payload, _, _|
      @obo_token_authenticator.invalidate_token(payload['obo']) if payload['obo']
    end
  end

  def verify_token(token, allow_ta: false, allow_obo: false, require_obo_scope: nil)
    raise ArgumentError if !allow_ta && !allow_obo
    raise ArgumentError if !allow_obo && require_obo_scope

    options = {
      algorithm: 'RS256',
      verify_jti: -> (jti) { jti =~ JTI_PATTERN },
    }

    payload, header = JWT.decode(token, @public_key, true, options)

    cty, obo = header['cty'], payload['obo']

    if obo
      raise JWT::DecodeError unless obo_token_support?
      raise JWT::InvalidPayload unless allow_obo
      raise JWT::InvalidPayload if cty != 'JWT'

      # TODO scope JTIs per OBO SUB or not? (currently not scoped)

      sub, ass = nil, @obo_token_authenticator.verify_token(obo, scope: require_obo_scope)
    else
      raise JWT::InvalidPayload unless allow_ta
      raise JWT::InvalidPayload if cty

      # TODO set SUB here according to underlying TA

      sub, ass = nil
    end

    exp, jti = payload['exp'], payload['jti']

    raise JWT::ExpiredSignature unless exp.is_a?(Integer)
    raise JWT::InvalidPayload if exp > (Time.now + MAX_EXP_IN).to_i
    raise JWT::InvalidJtiError unless @identifier_store.write([sub, jti], true, expires_in: MAX_EXP_IN, unless_exist: true)

    return yield payload, header, ass if block_given?

    ass
  end

  private

  def obo_token_support?
    !!@obo_token_authenticator
  end
end
