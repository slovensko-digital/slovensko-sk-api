module AuthenticityTokens
  def self.fetch_key_pair(prefix, write_public_key: false)
    path = Rails.root.join('security', "#{prefix}_token_#{Rails.env}.private.pem")
    File.write(path, OpenSSL::PKey::RSA.new(2048).to_s) unless File.exist?(path)
    key_pair = OpenSSL::PKey::RSA.new(File.read(path))

    if write_public_key
      path = path.sub('private', 'public')
      File.write(path, key_pair.public_key.to_s) unless File.exist?(path)
    end

    key_pair
  end

  mattr_accessor :api_token_key_pair, default: fetch_key_pair(:api, write_public_key: true)
  mattr_accessor :obo_token_key_pair, default: fetch_key_pair(:obo)

  mattr_accessor :sso_response_file, default: 'oam/sso_response_success.xml'
  mattr_accessor :sso_response_issued_at, default: '2018-11-28T20:26:16Z'

  def api_token
    api_token_with_subject(nil)
  end

  def api_token_with_subject(subject = 'CIN-11190868', expires_in: 20.minutes.from_now)
    payload = { sub: subject, exp: expires_in.to_i, jti: SecureRandom.uuid }
    JWT.encode(payload, api_token_key_pair, 'RS256')
  end

  def api_token_with_obo_token(response = file_fixture(sso_response_file).read, scopes: [])
    response = OneLogin::RubySaml::Response.new(response) unless response.is_a?(OneLogin::RubySaml::Response)
    obo = obo_token_from_response(response, scopes: scopes)
    payload = { exp: response.not_on_or_after.to_i, jti: SecureRandom.uuid, obo: obo }
    JWT.encode(payload, api_token_key_pair, 'RS256', { cty: 'JWT' })
  end

  def obo_token_from_response(response, scopes: [])
    response = OneLogin::RubySaml::Response.new(response) unless response.is_a?(OneLogin::RubySaml::Response)
    Environment.obo_token_authenticator.generate_token(response, scopes: scopes)
  end
end

RSpec.configure do |config|
  config.include AuthenticityTokens
end
