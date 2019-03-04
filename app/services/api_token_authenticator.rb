# See https://tools.ietf.org/html/rfc7519

class ApiTokenAuthenticator
  MAX_EXP_IN = OboTokenAuthenticator::MAX_EXP_IN
  JTI_PATTERN = /^[0-9a-z-_]{1,256}$/

  def initialize(identifier_store:, public_key:, obo_token_authenticator:)
    @identifier_store = identifier_store
    @public_key = public_key
    @obo_token_authenticator = obo_token_authenticator
  end

  def invalidate_token(token, require_obo: false)
    verify_token(token, require_obo: require_obo) do |payload, _|
      @obo_token_authenticator.invalidate_token(payload['obo']) if payload['obo']
    end
  end

  def verify_token(token, require_obo: false, scope: nil)
    options = {
      algorithm: 'RS256',
      verify_jti: -> (jti) { jti =~ JTI_PATTERN },
    }

    payload, header = JWT.decode(token, @public_key, true, options)

    cty = header['cty']

    raise JWT::DecodeError if payload['obo'] ? !obo_token_support? || cty != 'JWT' : cty != nil
    raise JWT::InvalidPayload if require_obo && payload['obo'].blank?

    exp, jti = payload['exp'], payload['jti']

    raise JWT::ExpiredSignature unless exp.is_a?(Integer)
    raise JWT::InvalidPayload if exp > (Time.now + MAX_EXP_IN).to_i
    raise JWT::InvalidJtiError unless @identifier_store.write(jti, true, expires_in: MAX_EXP_IN, unless_exist: true)

    return yield payload, header if block_given?

    @obo_token_authenticator.verify_token(payload['obo'], scope: scope) if require_obo || payload['obo']
  end

  private

  def obo_token_support?
    !!@obo_token_authenticator
  end
end
