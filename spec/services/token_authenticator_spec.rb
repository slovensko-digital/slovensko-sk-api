require 'rails_helper'

RSpec.describe TokenAuthenticator do
  let(:assertion_store) { ActiveSupport::Cache::MemoryStore.new }
  let(:key_pair) { OpenSSL::PKey::RSA.new(2048) }

  let(:response) { OneLogin::RubySaml::Response.new(file_fixture('oam/response_success.xml').read) }
  let(:assertion) { file_fixture('oam/response_success_assertion.xml').read.strip }

  subject { described_class.new(assertion_store: assertion_store, key_pair: key_pair) }

  before(:example) { travel_to '2018-11-28T20:26:16Z' }

  after(:example) { travel_back }

  describe '#generate_token' do
    it 'returns token' do
      token = subject.generate_token(response, scopes: ['sktalk:receive'])

      payload, header = JWT.decode(token, key_pair.public_key, false)

      expect(header).to match(
        'alg' => 'RS256',
      )

      expect(payload).to match(
        'sub' => 'rc://sk/8314451337_tisici_janko',
        'exp' => 1543437976,
        'nbf' => 1543436776,
        'iat' => 1543436776.0,
        'jti' => kind_of(String),
        'name' => 'Janko Tisíci',
        'scopes' => ['sktalk:receive'],
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

      expect(assertion_store).to receive(:write).with(any_args).and_wrap_original do |m, j, a, o|
        expect(j).to be_a(String)
        expect(a).to eq(assertion)
        expect(o).to eq(expires_in: 20.minutes)

        m.call(jti = j, a, o)
      end

      token = subject.generate_token(response)

      payload, _ = JWT.decode(token, key_pair.public_key, false)

      expect(payload['jti']).to eq(jti)

      expect(assertion_store.inspect).to match('entries=1,')
      expect(assertion_store.read(jti)).to eq(assertion)
    end

    context 'assertion parser failure' do
      let(:response) { OneLogin::RubySaml::Response.new(file_fixture('oam/response_no_authn_context.xml').read) }

      it 'raises argument error' do
        expect { subject.generate_token(response) }.to raise_error(ArgumentError)
      end

      it 'does not write anything to assertion store' do
        suppress(ArgumentError) { subject.generate_token(response) }

        expect(assertion_store.inspect).to match('entries=0,')
      end
    end

    context 'response creation to expiration relation check failure' do
      before(:example) { expect(response).to receive(:not_on_or_after).and_wrap_original { |m| m.call + 41.minutes }}

      it 'raises argument error' do
        expect { subject.generate_token(response) }.to raise_error(ArgumentError)
      end

      it 'does not write anything to assertion store' do
        suppress(ArgumentError) { subject.generate_token(response) }

        expect(assertion_store.inspect).to match('entries=0,')
      end
    end

    context 'response creation to usage relation check failure' do
      before(:example) { expect(response).to receive(:not_before).and_wrap_original { |m| m.call - 1.minute }}

      it 'raises argument error' do
        expect { subject.generate_token(response) }.to raise_error(ArgumentError)
      end

      it 'does not write anything to assertion store' do
        suppress(ArgumentError) { subject.generate_token(response) }

        expect(assertion_store.inspect).to match('entries=0,')
      end
    end

    context 'response expiration check failure' do
      before(:example) { travel_to Time.now + 20.minutes }

      it 'raises argument error' do
        expect { subject.generate_token(response) }.to raise_error(ArgumentError)
      end

      it 'does not write anything to assertion store' do
        suppress(ArgumentError) { subject.generate_token(response) }

        expect(assertion_store.inspect).to match('entries=0,')
      end
    end

    context 'token encoder failure' do
      before(:example) { expect(JWT).to receive(:encode).with(any_args).and_raise(JWT::EncodeError) }

      it 'raises encode error' do
        expect { subject.generate_token(response) }.to raise_error(JWT::EncodeError)
      end

      it 'does not write anything to assertion store' do
        suppress(JWT::EncodeError) { subject.generate_token(response) }

        expect(assertion_store.inspect).to match('entries=0,')
      end
    end
  end

  describe '#invalidate_token' do
    let!(:token) { subject.generate_token(response) }

    it 'returns true' do
      expect(subject.invalidate_token(token)).to be true
    end

    it 'verifies token' do
      expect(subject).to receive(:verify_token).with(token).and_call_original

      subject.invalidate_token(token)
    end

    it 'deletes assertion from store' do
      payload, _ = JWT.decode(token, key_pair.public_key, false)

      expect(assertion_store).to receive(:delete).with(payload['jti']).and_call_original

      subject.invalidate_token(token)

      expect(assertion_store.inspect).to match('entries=0,')
    end

    context 'token verification failure' do
      before(:example) { expect(subject).to receive(:verify_token).with(token).and_raise(JWT::DecodeError) }

      it 'raises decode error' do
        expect { subject.invalidate_token(token) }.to raise_error(JWT::DecodeError)
      end

      it 'does not delete assertion from store' do
        suppress(JWT::DecodeError) { subject.invalidate_token(token) }

        expect(assertion_store.inspect).to match('entries=1,')
      end
    end
  end

  describe '#verify_token' do
    def generate_token(sub: 'rc://sk/8314451337_tisici_janko', exp: 1543437976, nbf: 1543436776, iat: 1543436776.0, jti: SecureRandom.uuid, header: {}, **payload)
      payload.merge!(sub: sub, exp: exp, nbf: nbf, iat: iat, jti: jti)
      assertion_store.write(jti, assertion) if jti
      JWT.encode(payload.compact, key_pair, 'RS256', header)
    end

    it 'returns assertion' do
      expect(subject.verify_token(generate_token)).to eq(assertion)
    end

    it 'verifies format' do
      expect { subject.verify_token(nil) }.to raise_error(JWT::DecodeError)
      expect { subject.verify_token('NON-JWT') }.to raise_error(JWT::DecodeError)
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

      expect { subject.verify_token(token) }.to raise_error(JWT::ExpiredSignature)
    end

    it 'verifies EXP claim format' do
      token = generate_token(exp: 'non-integer-value')

      expect { subject.verify_token(token) }.to raise_error(JWT::ExpiredSignature)
    end

    it 'verifies EXP claim value' do
      token = generate_token

      travel_to Time.now + 20.minutes

      expect { subject.verify_token(token) }.to raise_error(JWT::ExpiredSignature)
    end

    it 'verifies EXP to IAT claim relation' do
      token = generate_token(exp: (response.not_on_or_after + 41.minutes).to_i)

      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidPayload)
    end

    it 'verifies NBF claim presence' do
      token = generate_token(nbf: nil)

      expect { subject.verify_token(token) }.to raise_error(JWT::ImmatureSignature)
    end

    it 'verifies NBF claim format' do
      token = generate_token(nbf: 'non-integer-value')

      expect { subject.verify_token(token) }.to raise_error(JWT::ImmatureSignature)
    end

    it 'verifies NBF claim value' do
      token = generate_token

      travel_to Time.now - 0.1.seconds

      expect { subject.verify_token(token) }.to raise_error(JWT::ImmatureSignature)
    end

    it 'verifies NBF to IAT claim relation' do
      token = generate_token(nbf: (response.not_before - 1.minute).to_i)

      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidPayload)
    end

    it 'verifies IAT claim presence' do
      token = generate_token(iat: nil)

      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidIatError)
    end

    it 'verifies IAT claim format' do
      token = generate_token(iat: 'non-numeric-value')

      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidIatError)
    end

    it 'verifies IAT claim value' do
      token = generate_token(iat: Time.now + 0.1.seconds)

      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidIatError)
    end

    it 'verifies JTI claim presence' do
      token = generate_token(jti: nil)

      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidJtiError)
    end

    it 'verifies JTI claim value' do
      token = generate_token

      assertion_store.clear
      expect(assertion_store.inspect).to match('entries=0,')

      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidJtiError)
    end

    it 'verifies SCOPES claim presence' do
      token = generate_token(scopes: [])

      expect { subject.verify_token(token, scopes: 'scope-to-verify') }.to raise_error(JWT::VerificationError)
    end

    it 'verifies SCOPES claim value' do
      token = generate_token(scopes: ['scope-to-permit'])

      expect { subject.verify_token(token, scopes: 'scope-to-verify') }.to raise_error(JWT::VerificationError)
    end

    context 'token decoder failure' do
      before(:example) { expect(JWT).to receive(:decode).with(any_args).and_raise(JWT::DecodeError) }

      it 'raises decode error' do
        expect { subject.verify_token(generate_token) }.to raise_error(JWT::DecodeError)
      end
    end
  end
end
