require 'rails_helper'

RSpec.describe OboTokenAuthenticator do
  # time epsilon is set to 1 second by time helpers to prevent rounding errors with external services

  let(:assertion_store) { redis_cache_store_in_ruby_memory }
  let(:key_pair) { obo_token_key_pair }
  let(:proxy_subject) { 'CIN-83130022' }

  let(:response) { OneLogin::RubySaml::Response.new(file_fixture('oam/sso_response_success.xml').read) }
  let(:assertion) { file_fixture('oam/sso_response_success_assertion.xml').read.strip }

  subject { described_class.new(assertion_store: assertion_store, key_pair: key_pair, proxy_subject: proxy_subject) }

  before(:example) { allow(JWT::ClaimsValidator).to receive_message_chain(:new, :validate!).with(any_args) }

  before(:example) { assertion_store.clear }

  before(:example) { travel_to '2018-11-28T20:26:16Z' }

  delegate :now, to: Time

  describe '#generate_token' do
    it 'returns token' do
      token = subject.generate_token(response, scopes: ['sktalk/receive'])

      payload, header = JWT.decode(token, key_pair.public_key, false)

      expect(header).to match(
        'alg' => 'RS256',
      )

      expect(payload).to match(
        'sub' => 'rc://sk/8314451337_tisici_janko',
        'exp' => 1543437976,
        'nbf' => 1543436776,
        'iat' => 1543436776,
        'jti' => kind_of(String),
        'name' => 'Janko Tisíci',
        'actor' => {
          'name' => 'Janko Tisíci',
          'sub' => 'rc://sk/8314451337_tisici_janko'
        },
        'scopes' => ['sktalk/receive'],
      )
    end

    it 'returns unique token for the same response' do
      t1 = subject.generate_token(response)
      t2 = subject.generate_token(response)

      expect(t1).not_to eq(t2)

      j1 = JWT.decode(t1, key_pair.public_key, false).first['jti']
      j2 = JWT.decode(t2, key_pair.public_key, false).first['jti']

      expect(j1).not_to eq(j2)
    end

    it 'writes assertion to store' do
      jti = nil

      options = { expires_in: response.not_on_or_after - response.not_before, unless_exist: true }
      expect(assertion_store).to receive(:write).with(satisfy { |s| jti = s }, assertion, options).and_call_original

      token = subject.generate_token(response)

      payload, _ = JWT.decode(token, key_pair.public_key, false)

      expect(payload['jti']).to eq(jti)

      expect(assertion_store.keys.size).to eq(1)
      expect(assertion_store.read(jti)).to eq(assertion)
    end

    context 'response that was issued after being usable' do
      before(:example) { expect(response).to receive(:not_before).and_return(1.second.ago) }

      it 'raises argument error' do
        expect { subject.generate_token(response) }.to raise_error(ArgumentError, 'iat')
      end

      it 'does not write anything to assertion store' do
        suppress(ArgumentError) { subject.generate_token(response) }
        expect(assertion_store.keys.size).to eq(0)
      end
    end

    context 'response that is not usable yet' do
      before(:example) { expect(response).to receive(:not_before).and_return(1.second.from_now) }

      it 'raises argument error' do
        expect { subject.generate_token(response) }.to raise_error(ArgumentError, 'nbf')
      end

      it 'does not write anything to assertion store' do
        suppress(ArgumentError) { subject.generate_token(response) }
        expect(assertion_store.keys.size).to eq(0)
      end
    end

    context 'response that expired in the past' do
      before(:example) { expect(response).to receive(:not_on_or_after).and_return(1.second.ago) }

      it 'raises argument error' do
        expect { subject.generate_token(response) }.to raise_error(ArgumentError, 'exp')
      end

      it 'does not write anything to assertion store' do
        suppress(ArgumentError) { subject.generate_token(response) }
        expect(assertion_store.keys.size).to eq(0)
      end
    end

    context 'response that expired just now' do
      before(:example) { expect(response).to receive(:not_on_or_after).and_return(now) }

      it 'raises argument error' do
        expect { subject.generate_token(response) }.to raise_error(ArgumentError, 'exp')
      end

      it 'does not write anything to assertion store' do
        suppress(ArgumentError) { subject.generate_token(response) }
        expect(assertion_store.keys.size).to eq(0)
      end
    end

    context 'response that is expiring just about now' do
      before(:example) { expect(assertion_store).to receive(:write).and_wrap_original { travel_to(response.not_on_or_after) and false }}

      it 'raises argument error' do
        expect { subject.generate_token(response) }.to raise_error(ArgumentError, 'exp')
      end

      it 'does not write anything to assertion store' do
        suppress(ArgumentError) { subject.generate_token(response) }
        expect(assertion_store.keys.size).to eq(0)
      end
    end

    context 'assertion parser failure' do
      let(:response) { OneLogin::RubySaml::Response.new(file_fixture('oam/sso_response_no_authn_context.xml').read) }

      it 'raises argument error' do
        expect { subject.generate_token(response) }.to raise_error(ArgumentError)
      end

      it 'does not write anything to assertion store' do
        suppress(ArgumentError) { subject.generate_token(response) }
        expect(assertion_store.keys.size).to eq(0)
      end
    end

    context 'token encoder failure' do
      before(:example) { expect(JWT).to receive(:encode).with(any_args).and_raise(JWT::EncodeError) }

      it 'raises encode error' do
        expect { subject.generate_token(response) }.to raise_error(JWT::EncodeError)
      end

      it 'does not write anything to assertion store' do
        suppress(JWT::EncodeError) { subject.generate_token(response) }
        expect(assertion_store.keys.size).to eq(0)
      end
    end

    context 'getting OBO public key' do
      it 'gets valid OBO public key' do
        private_key = <<KEY
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDV6tu6c3soJajF
i7dh2wM+qBfD38a/E2DkL3xn45/iFIg5/3zmij3ebOwilluiaupn8xAHjtlgBjaU
hojgULO3GaEYWeKhng/0IjRFk+BOliYo8W+TxwW0930ajj7MSLH8/YWws50gtC0B
11vJJuFxGzi+HNvvIgk945bvcPNBbx3fbM1LKruPKAiGdQuNmeAvRtWEyrPOOpLE
iW6f0LcrC46opSW2m86WsyLV+K3iRidJgYoKKNNlSNYn1q7ruwVBzKKjj9nxdHQc
kAXRQ3KSuYoQkoph8xeycKNRnxNOWF93VnuoZySg0F4uclwlcfrU+csa0eXZFRr0
pIPguHSpAgMBAAECggEBAJ4vyYKsSONcTdyfP+GWAmVACirnfOHpY5n534Y3lhCp
3D7/Rg55Jd0oMMo249ZMN8DcxfrA0NAoaA4XGnq+UtdQlYcbWPLonqWK8ZqOCq4y
bE+Ukkz2PKsg5JtRmvCXxT7u/wC3IbeAZVPaPF6YaNeqKKC1WJISWkEw3nl7zfaQ
6Vo0YzApP93vv4wDWrcP7EI/x/LXB47i+iOAA6EMbhLSn4y+QUmkYgkLvG7ZaSv6
rhFlUlnm1eC9Rv1xhKZVrxLfRAfOrfaSZrLydeJZWqTgJLmrWYXpFKZi+iYs/sXX
gdjmuAgBXb9vLaQPD58Ej65bqhT5tMd27juPZ6abKQECgYEA9F7nbcKYTgxKLfK0
MtWLiJSiI9U3wt2oAawT+2dFidWJjIYsFVnhLOxxbUhOxE+xAecWeZhXCSyAobkL
dOCMjI9hOsu67T7baa6MMRhrGXBfVG1qI93Y+brQ3tFqyeSiZ5qmiGmzrnXe1OY/
taEFEdu+I2nnZX3emRgMqFYMtckCgYEA4BjzYyIXbBAWencrvgOrgHvHNqEnOIQ0
+ozrKtCg3FEam+stkAxoKijVk4rVS+WR0Aar+bf38MD0qaqHlH/7182jSzJEgsTM
iYhUuI6yG+u2amNfZ6Uj3uNOA771ShRR1O7ML1KpOcPIxupjvyCikJV76FgSogfT
qOFKiHHKt+ECgYBTWEr2VHg9plNmeHCdJdgBLTBfqEjsXUz/xQDLrd05tWrEUr6W
SaFTARFuhErZCZUFYRt5PUvyBQuaHNKbejp1djFjLDkE0Xtj//QwinN8qabZ1Ldu
pCtsgRrb4/DYCvKZA1XpEKQHzIvDcQQpnlFsVdXznhsdsmBJNrqabz7GgQKBgGpW
LJerw6V5dNEj31PI9gZ/taYMjknZIjKJz8V/PfWNXq0ByZsC6CKpQb9DL7dV9fza
TZyvWS2awf4Id1FV8bETWRsDfVL4A353fIwe2hE5plORV+IckIrhHVHVuRsvzSzX
K3iBJt/MMWeCLVayK7Gj3SoBMMZGJH+MeAuKw4DBAoGBAOBkJVyqez2njr7Ah74Y
Ju+xZNapfQWbXT/hKL9hbVS6HYoyVwHqBLsqvp9gpMV7Y6VvZlsKKWxGVDcKktF6
xNpIapkSGYqR1lMlbo5vOSc5b+bnHNSOoXPBRDWaY+5ujUYMub12YGhf3kM0XYji
ASaA7F97TnfCTjMQjFZ+si+w
-----END PRIVATE KEY-----
KEY
        public_key = <<KEY
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1erbunN7KCWoxYu3YdsD
PqgXw9/GvxNg5C98Z+Of4hSIOf985oo93mzsIpZbomrqZ/MQB47ZYAY2lIaI4FCz
txmhGFnioZ4P9CI0RZPgTpYmKPFvk8cFtPd9Go4+zEix/P2FsLOdILQtAddbySbh
cRs4vhzb7yIJPeOW73DzQW8d32zNSyq7jygIhnULjZngL0bVhMqzzjqSxIlun9C3
KwuOqKUltpvOlrMi1fit4kYnSYGKCijTZUjWJ9au67sFQcyio4/Z8XR0HJAF0UNy
krmKEJKKYfMXsnCjUZ8TTlhfd1Z7qGckoNBeLnJcJXH61PnLGtHl2RUa9KSD4Lh0
qQIDAQAB
-----END PUBLIC KEY-----
KEY
        key_pair = OpenSSL::PKey::RSA.new(private_key)
        
        expect(key_pair.public_key.to_pem).to eq(public_key)
      end
    end

    context 'assertion store failure' do
      let(:assertion_store) { redis_cache_store_without_connection }

      it 'raises connection error' do
        expect { subject.generate_token(response) }.to raise_error(Environment::RedisConnectionError)
      end
    end
  end

  describe '#invalidate_token' do
    let(:token) { subject.generate_token(response) }

    it 'returns true' do
      expect(subject.invalidate_token(token)).to eq(true)
    end

    it 'verifies token' do
      expect(subject).to receive(:verify_token).with(token, verify_expiration: false).and_call_original

      subject.invalidate_token(token)
    end

    it 'deletes assertion from store' do
      payload, _ = JWT.decode(token, key_pair.public_key, false)

      expect(assertion_store).to receive(:delete).with(payload['jti']).and_call_original

      subject.invalidate_token(token)

      expect(assertion_store.keys.size).to eq(0)
    end

    context 'token verification failure' do
      before(:example) { expect(subject).to receive(:verify_token).with(token, verify_expiration: false).and_raise(JWT::DecodeError) }

      it 'raises decode error' do
        expect { subject.invalidate_token(token) }.to raise_error(JWT::DecodeError)
      end

      it 'does not delete assertion from store' do
        suppress(JWT::DecodeError) { subject.invalidate_token(token) }
        expect(assertion_store.keys.size).to eq(1)
      end
    end

    context 'assertion store failure' do
      let(:assertion_store) { redis_cache_store_without_connection }

      it 'raises connection error' do
        expect { subject.invalidate_token(token) }.to raise_error(Environment::RedisConnectionError)
      end
    end
  end

  describe '#verify_token' do
    def generate_token(sub: 'rc://sk/8314451337_tisici_janko', exp: 1543437976, nbf: 1543436776, iat: 1543436776, jti: SecureRandom.uuid, header: {}, **payload)
      payload.merge!(sub: sub, exp: exp, nbf: nbf, iat: iat, jti: jti)
      assertion_store.write(jti, assertion) if jti
      JWT.encode(payload.compact, key_pair, 'RS256', header)
    end

    it 'returns subject and assertion' do
      expect(subject.verify_token(generate_token)).to eq([proxy_subject, assertion])
    end

    it 'verifies format' do
      expect { subject.verify_token(nil) }.to raise_error(JWT::DecodeError)
      expect { subject.verify_token('?') }.to raise_error(JWT::DecodeError)
    end

    it 'verifies algorithm' do
      token = JWT.encode(nil, 'KEY', 'HS256')
      expect { subject.verify_token(token) }.to raise_error(JWT::IncorrectAlgorithm)
    end

    it 'verifies signature' do
      token = JWT.encode(nil, OpenSSL::PKey::RSA.new(2048), 'RS256')
      expect { subject.verify_token(token) }.to raise_error(JWT::VerificationError)
    end

    it 'verifies EXP claim presence' do
      token = generate_token(exp: nil)
      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidPayload, 'exp')
    end

    it 'verifies EXP claim format' do
      token = generate_token(exp: '?')
      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidPayload, 'exp')
    end

    it 'verifies EXP claim value (expired in the past)' do
      token = generate_token(exp: 1.second.ago.to_i)
      expect { subject.verify_token(token) }.to raise_error(JWT::ExpiredSignature, 'exp')
    end

    it 'verifies EXP claim value (expired now)' do
      token = generate_token(exp: now.to_i)
      expect { subject.verify_token(token) }.to raise_error(JWT::ExpiredSignature, 'exp')
    end

    it 'verifies EXP claim value (expired in the future)' do
      token = generate_token(exp: 1.second.from_now.to_i)
      subject.verify_token(token)
    end

    it 'verifies NBF claim presence' do
      token = generate_token(nbf: nil)
      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidPayload, 'nbf')
    end

    it 'verifies NBF claim format' do
      token = generate_token(nbf: '?')
      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidPayload, 'nbf')
    end

    it 'verifies NBF claim value (usable in the past) and IAT claim value (usable in the past)' do
      token = generate_token(iat: 1.second.ago.to_i, nbf: 1.second.ago.to_i)
      subject.verify_token(token)
    end

    it 'verifies NBF claim value (usable in the past) and IAT claim value (issued now)' do
      token = generate_token(nbf: 1.second.ago.to_i, iat: now.to_i)
      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidIatError, 'iat')
    end

    it 'verifies NBF claim value (usable now)' do
      token = generate_token(nbf: now.to_i)
      subject.verify_token(token)
    end

    it 'verifies NBF claim value (usable in the future)' do
      token = generate_token(nbf: 1.second.from_now.to_i)
      expect { subject.verify_token(token) }.to raise_error(JWT::ImmatureSignature, 'nbf')
    end

    it 'verifies IAT claim presence' do
      token = generate_token(iat: nil)
      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidPayload, 'iat')
    end

    it 'verifies IAT claim format' do
      token = generate_token(iat: '?')
      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidPayload, 'iat')
    end

    it 'verifies IAT claim value (issued before)' do
      token = generate_token(iat: 1.second.ago.to_i)
      subject.verify_token(token)
    end

    it 'verifies IAT claim value (issued now)' do
      token = generate_token(iat: now.to_i)
      subject.verify_token(token)
    end

    it 'verifies IAT claim value (issued in the future)' do
      token = generate_token(iat: 1.second.from_now.to_i)
      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidIatError, 'iat')
    end

    it 'verifies JTI claim presence' do
      token = generate_token(jti: nil)
      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidJtiError)
    end

    it 'verifies JTI claim value' do
      token = generate_token
      assertion_store.clear
      expect(assertion_store.keys.size).to eq(0)
      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidJtiError)
    end

    it 'verifies SCOPES claim presence' do
      token = generate_token(scopes: [])
      expect { subject.verify_token(token, scope: 'sktalk/receive') }.to raise_error(JWT::InvalidPayload, 'scope')
    end

    it 'verifies SCOPES claim value' do
      token = generate_token(scopes: ['edesk/authorize'])
      expect { subject.verify_token(token, scope: 'sktalk/receive') }.to raise_error(JWT::InvalidPayload, 'scope')
    end

    context 'token decoder failure' do
      before(:example) { expect(JWT).to receive(:decode).with(any_args).and_raise(JWT::DecodeError) }

      it 'raises decode error' do
        expect { subject.verify_token(generate_token) }.to raise_error(JWT::DecodeError)
      end
    end

    context 'assertion store failure' do
      let(:assertion_store) { redis_cache_store_without_connection }

      it 'raises connection error' do
        expect { subject.verify_token(generate_token) }.to raise_error(Environment::RedisConnectionError)
      end
    end
  end
end
