# See https://tools.ietf.org/html/rfc7519

class ApiTokenAuthenticator
  MAX_EXP_IN = OboTokenAuthenticator::MAX_EXP_IN
  JTI_PATTERN = /^[0-9a-z-_]{1,256}$/

  def initialize(jti_cache:, public_key:, obo_token_authenticator:)
    @jti_cache = jti_cache
    @public_key = public_key
    @obo_token_authenticator = obo_token_authenticator
  end

  def verify_token(token, scope: nil, obo: false)
    options = {
      algorithm: 'RS256',
      verify_jti: -> (jti) { jti =~ JTI_PATTERN },
    }

    payload, header = JWT.decode(token, @public_key, true, options)

    cty = header['cty']

    raise JWT::DecodeError unless cty == 'JWT'

    exp, jti = payload['exp'], payload['jti']

    raise JWT::ExpiredSignature unless exp.is_a?(Integer)
    raise JWT::InvalidPayload if exp > (Time.now + MAX_EXP_IN).to_i

    @jti_cache.synchronize do
      raise JWT::InvalidJtiError if @jti_cache.exist?(jti)
      @jti_cache.write(jti, true, expires_in: MAX_EXP_IN)
    end

    obo ? @obo_token_authenticator.verify_token(payload['obo'], scope: scope) : true
  end
end
