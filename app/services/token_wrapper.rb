class TokenWrapper
  def initialize(token_authenticator:, public_key:)
    @token_authenticator = token_authenticator
    @public_key = public_key
  end

  def unwrap(token)
    payload = JWT.decode(token, @public_key, true, algorithm: 'RS256').first

    # TODO force cty: "JWT" header check because this JWT carries another JWT in it
    # TODO force claim checks on jti (replay attacks) and exp here

    @token_authenticator.verify_token(payload['obo'])
  end

  alias_method :verify_token, :unwrap
end
