# See https://tools.ietf.org/html/rfc7519

class ApiTokenAuthenticator
  MAX_EXP_IN = OboTokenAuthenticator::MAX_EXP_IN
  JTI_PATTERN = /^[0-9a-z-_]{1,256}$/

  def initialize(jti_cache:, public_key:, obo_token_authenticator:)
    @jti_cache = jti_cache
    @public_key = public_key
    @obo_token_authenticator = obo_token_authenticator
  end

  def verify_token(token, obo: false, scope: nil)
    raise ArgumentError if !obo && scope

    options = {
      algorithm: 'RS256',
      verify_jti: -> (jti) { jti =~ JTI_PATTERN },
    }

    payload, header = JWT.decode(token, @public_key, true, options)

    cty = header['cty']

    raise JWT::DecodeError if payload['obo'] ? cty != 'JWT' : cty != nil

    exp, jti = payload['exp'], payload['jti']

    raise JWT::ExpiredSignature unless exp.is_a?(Integer)
    raise JWT::InvalidPayload if exp > (Time.now + MAX_EXP_IN).to_i

    @jti_cache.synchronize do
      raise JWT::InvalidJtiError if @jti_cache.exist?(jti)
      @jti_cache.write(jti, true, expires_in: MAX_EXP_IN)
    end

    return yield payload, header if block_given?

    obo ? @obo_token_authenticator.verify_token(payload['obo'], scope: scope) : true
  end

  def invalidate_token(token, obo: false, scope: nil)
    verify_token(token, obo: obo, scope: scope) do |payload, _|
      @obo_token_authenticator.invalidate_token(payload['obo'])
    end
  end
end
