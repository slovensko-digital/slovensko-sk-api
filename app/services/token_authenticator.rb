# See https://tools.ietf.org/html/rfc7519

class TokenAuthenticator
  EXP_IN = 20.minutes
  JTI_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

  def initialize(assertion_store:, key_pair:)
    @assertion_store = assertion_store
    @key_pair = key_pair
  end

  def generate_token(response)
    assertion = parse_assertion(response)

    # TODO maybe return some user specific data in payload here

    @assertion_store.synchronize do
      exp = response.not_on_or_after.to_i
      nbf = response.not_before.to_i
      iat = Time.parse(assertion.attributes['IssueInstant']).to_f

      raise ArgumentError if exp != iat + EXP_IN || nbf != iat

      jti = generate_jti
      ass = assertion_to_s(assertion)

      payload = { exp: exp, nbf: nbf, iat: iat, jti: jti }
      exp_in = exp - Time.now.to_f

      raise ArgumentError if exp_in <= 0

      JWT.encode(payload, @key_pair, 'RS256').tap { @assertion_store.write(jti, ass, expires_in: exp_in) }
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
    options = {
      algorithm: 'RS256',
      verify_iat: true,
      verify_jti: -> (jti) { jti =~ JTI_PATTERN },
    }

    payload, header = JWT.decode(token, @key_pair.public_key, true, options)

    raise JWT::DecodeError if header.keys != ['alg']
    raise JWT::InvalidPayload if payload.keys - ['exp', 'nbf', 'iat', 'jti'] != []

    exp, nbf, iat, jti = payload['exp'], payload['nbf'], payload['iat'], payload['jti']

    raise JWT::ExpiredSignature unless exp.is_a?(Integer)
    raise JWT::ImmatureSignature unless nbf.is_a?(Integer)
    raise JWT::InvalidIatError unless iat.is_a?(Numeric)

    raise JWT::InvalidPayload if exp != iat + EXP_IN
    raise JWT::InvalidPayload if nbf != iat

    ass = @assertion_store.read(jti)

    raise JWT::InvalidJtiError unless ass

    block_given? ? yield(payload, header, ass) : ass
  end

  private

  def generate_jti
    loop do
      jti = SecureRandom.uuid
      return jti unless @assertion_store.exist?(jti)
    end
  end

  def parse_assertion(response)
    document = response.decrypted_document || response.document
    assertion = REXML::XPath.first(document, '//saml:Assertion')

    raise ArgumentError unless assertion

    # force namespaces directly on element, otherwise they are not present
    assertion.namespaces.slice('dsig', 'saml', 'xsi').each do |prefix, uri|
      assertion.add_namespace(prefix, uri)
    end

    # force double quotes on attributes, actually preserve response format
    assertion.context[:attribute_quote] = :quote

    assertion
  end

  def assertion_to_s(assertion)
    formatter = REXML::Formatters::Pretty.new(0)
    formatter.compact = true
    formatter.write(assertion, buffer = '')
    buffer.remove("\n")
  end
end
