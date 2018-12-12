# TODO rename upvs_token_key_pair -> obo_token_key_pair

module SecurityKeys
  mattr_accessor :api_token_key_pair, default: OpenSSL::PKey::RSA.new(2048)
  mattr_accessor :upvs_token_key_pair, default: OpenSSL::PKey::RSA.new(2048)
end

RSpec.configure do |config|
  config.include SecurityKeys

  config.before(:suite) do
    File.write(ENV['API_TOKEN_PUBLIC_KEY_FILE'], SecurityKeys.api_token_key_pair.public_key.to_s)
    File.write(ENV['UPVS_TOKEN_PRIVATE_KEY_FILE'], SecurityKeys.upvs_token_key_pair.to_s)
  end

  config.after(:suite) do
    File.delete(ENV['API_TOKEN_PUBLIC_KEY_FILE'])
    File.delete(ENV['UPVS_TOKEN_PRIVATE_KEY_FILE'])
  end
end
