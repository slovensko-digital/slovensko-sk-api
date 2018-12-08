# See https://tools.ietf.org/html/rfc7519

# TODO consider renaming:
# TokenAuthenticator -> UpvsTokenAuthenticator
# TokenWrapper -> ApiTokenAuthenticator: #unwrap -> #verify_token

class TokenWrapper
  EXP_IN = TokenAuthenticator::EXP_IN
  JTI_PATTERN = TokenAuthenticator::JTI_PATTERN

  def initialize(token_authenticator:, public_key:, jti_cache:)
    @token_authenticator = token_authenticator
    @public_key = public_key
    @jti_cache = jti_cache
  end

  def unwrap(token)
    options = {
      algorithm: 'RS256',
      verify_jti: -> (jti) { jti =~ JTI_PATTERN },
    }

    payload, header = JWT.decode(token, @public_key, true, options)

    cty = header['cty']

    raise JWT::DecodeError unless cty == 'JWT'

    exp, jti = payload['exp'], payload['jti']

    raise JWT::ExpiredSignature unless exp.is_a?(Integer)
    raise JWT::InvalidPayload if !exp.is_a?(Integer) || exp > (Time.now + EXP_IN).to_i

    @jti_cache.synchronize do
      raise JWT::InvalidJtiError if @jti_cache.exist?(jti)
      @jti_cache.write(jti, true, expires_in: EXP_IN)
    end

    @token_authenticator.verify_token(payload['obo'])
  end

  alias_method :verify_token, :unwrap
end
