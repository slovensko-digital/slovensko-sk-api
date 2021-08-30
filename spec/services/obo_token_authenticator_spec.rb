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
      expect(subject).to receive(:verify_token).with(token).and_call_original

      subject.invalidate_token(token)
    end

    it 'deletes assertion from store' do
      payload, _ = JWT.decode(token, key_pair.public_key, false)

      expect(assertion_store).to receive(:delete).with(payload['jti']).and_call_original

      subject.invalidate_token(token)

      expect(assertion_store.keys.size).to eq(0)
    end

    context 'token verification failure' do
      before(:example) { expect(subject).to receive(:verify_token).with(token).and_raise(JWT::DecodeError) }

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
