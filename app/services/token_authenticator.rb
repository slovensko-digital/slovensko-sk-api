# TODO specs must cover every claim verification!

# See https://tools.ietf.org/html/rfc7519#section-4

class TokenAuthenticator
  def initialize(assertion_store:, private_key:)
    @assertion_store = assertion_store
    @private_key = private_key
  end

  def generate_token(response)
    document = response.decrypted_document || response.document
    assertion = REXML::XPath.first(document, '//saml:Assertion')

    @assertion_store.synchronize do
      payload = {
        exp: response.not_on_or_after.to_i,
        nbf: response.not_before.to_i,
        iat: Time.parse(assertion.attributes['IssueInstant']).to_i,
        jti: generate_jti,
      }

      @assertion_store.write(payload[:jti], assertion.to_s, expires_in: payload[:exp])

      JWT.encode(payload, @private_key, 'RS256')
    end
  end

  def invalidate_token(token)
    @assertion_store.synchronize do
      verify_token(token) do |payload, _, _|
        @assertion_store.delete(payload['jti'])
      end
    end
  end

  def verify_token(token)
    assertion = nil
    options = {
      algorithm: 'RS256',
      verify_iat: true,
      verify_jti: -> (jti) { assertion = @assertion_store.read(jti) },
    }

    payload, header = JWT.decode(token, @private_key.public_key, true, options)
    block_given? ? yield(payload, header, assertion) : assertion
  end

  private

  def generate_jti
    loop do
      jti = SecureRandom.uuid
      return jti unless @assertion_store.exist?(jti)
    end
  end
end
