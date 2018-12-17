module SecurityKeys
  mattr_accessor :api_token_key_pair, default: OpenSSL::PKey::RSA.new(2048)
  mattr_accessor :obo_token_key_pair, default: OpenSSL::PKey::RSA.new(2048)
end

RSpec.configure do |config|
  config.include SecurityKeys

  config.before(:suite) do
    File.write(ENV['API_TOKEN_PUBLIC_KEY_FILE'], SecurityKeys.api_token_key_pair.public_key.to_s)
    File.write(ENV['OBO_TOKEN_PRIVATE_KEY_FILE'], SecurityKeys.obo_token_key_pair.to_s)
  end

  config.after(:suite) do
    File.delete(ENV['API_TOKEN_PUBLIC_KEY_FILE'])
    File.delete(ENV['OBO_TOKEN_PRIVATE_KEY_FILE'])
  end
end
