# TODO specs must cover every claim verification!

# See https://tools.ietf.org/html/rfc7519#section-4

class TokenAuthenticator
  def initialize(assertion_store:, private_key:, issuer:, audience: nil)
    @assertion_store = assertion_store
    @private_key = private_key
    @issuer = issuer
    @audience = audience
  end

  def generate_token(response)
    document = response.decrypted_document || response.document
    assertion = REXML::XPath.first(document, '//saml:Assertion')

    @assertion_store.synchronize do
      payload = {
        iss: @issuer,
        sub: response.attributes['SubjectID'],
        aud: @audience,
        exp: exp = response.not_on_or_after.to_i,
        nbf: response.not_before.to_i,
        iat: Time.parse(assertion.attributes['IssueInstant']).to_i,
        jti: jti = generate_jti,
      }

      @assertion_store.write(jti, assertion, expires_in: exp)

      JWT.encode(payload, @private_key, 'RS256')
    end
  end

  def invalidate_token(token)
    @assertion_store.synchronize do
      payload, _, _ = verify_token(token)

      @assertion_store.delete(payload['jti'])
    end
  end

  def verify_token(token)
    assertion = nil
    options = {
      algorithm: 'RS256',
      iss: @issuer,
      # sub: ,
      aud: @audience,
      verify_iss: true,
      # verify_sub: true, # TODO verify sub somehow? otherwise remove sub or it can be tampered with
      verify_aud: true,
      verify_iat: true,
      verify_jti: -> (jti) { assertion = @assertion_store.read(jti) },
    }

    JWT.decode(token, @private_key.public_key, true, options) + [assertion]
  end

  private

  def generate_jti
    loop do
      jti = SecureRandom.uuid
      return jti unless @assertion_store.exist?(jti)
    end
  end
end
