module AuthenticityTokens
  mattr_accessor :api_token_key_pair, default: OpenSSL::PKey::RSA.new(2048)
  mattr_accessor :obo_token_key_pair, default: OpenSSL::PKey::RSA.new(2048)

  def api_token_without_obo_token(expires_in: Time.now + 20.minutes)
    payload = { exp: expires_in.to_i, jti: SecureRandom.uuid }
    JWT.encode(payload, api_token_key_pair, 'RS256')
  end

  def api_token_with_obo_token_from_response(response, scopes: [])
    response = OneLogin::RubySaml::Response.new(response) unless response.is_a?(OneLogin::RubySaml::Response)
    obo = obo_token_from_response(response, scopes: scopes)
    payload = { exp: response.not_on_or_after.to_i, jti: SecureRandom.uuid, obo: obo }
    JWT.encode(payload, api_token_key_pair, 'RS256', { cty: 'JWT' })
  end

  def obo_token_from_response(response, scopes: [])
    response = OneLogin::RubySaml::Response.new(response) unless response.is_a?(OneLogin::RubySaml::Response)
    travel_to(response.not_before) { Environment.obo_token_authenticator.generate_token(response, scopes: scopes) }
  end
end

RSpec.configure do |config|
  config.include AuthenticityTokens

  config.before(:suite) do
    File.write(ENV['API_TOKEN_PUBLIC_KEY_FILE'], AuthenticityTokens.api_token_key_pair.public_key.to_s)
    File.write(ENV['OBO_TOKEN_PRIVATE_KEY_FILE'], AuthenticityTokens.obo_token_key_pair.to_s)
  end

  config.after(:suite) do
    File.delete(ENV['API_TOKEN_PUBLIC_KEY_FILE'])
    File.delete(ENV['OBO_TOKEN_PRIVATE_KEY_FILE'])
  end
end
