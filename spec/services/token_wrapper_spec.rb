require 'rails_helper'

RSpec.describe TokenWrapper do
  let(:key_pair) { OpenSSL::PKey::RSA.new(2048) }
  let(:jti_cache) { ActiveSupport::Cache::MemoryStore.new }

  let(:upvs_token_authenticator) { UpvsEnvironment.token_authenticator }

  let(:response) { OneLogin::RubySaml::Response.new(file_fixture('oam/response_success.xml').read) }
  let(:assertion) { file_fixture('oam/response_success_assertion.xml').read.strip }

  subject { described_class.new(token_authenticator: upvs_token_authenticator, public_key: key_pair.public_key, jti_cache: jti_cache) }

  before(:example) { travel_to '2018-11-28T20:26:16Z' }

  after(:example) { travel_back }

  describe '#verify_token' do
    let(:upvs_token) { upvs_token_authenticator.generate_token(response) }

    def generate_token(exp: 1543437976, jti: SecureRandom.uuid, obo: upvs_token, header: { cty: 'JWT' }, **payload)
      payload.merge!(exp: exp, jti: jti, obo: obo)
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

    it 'verifies CTY header presence' do
      token = generate_token(header: {})

      expect { subject.verify_token(token) }.to raise_error(JWT::DecodeError)
    end

    it 'verifies CTY header value' do
      token = generate_token(header: { cty: 'NON-JWT' })

      expect { subject.verify_token(token) }.to raise_error(JWT::DecodeError)
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

    it 'verifies EXP claim to OBO token relation' do
      token = generate_token(exp: (Time.now + 20.minutes + 2.seconds).to_i)

      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidPayload)
    end

    it 'verifies JTI claim presence' do
      token = generate_token(jti: nil)

      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidJtiError)
    end

    it 'verifies JTI claim format' do
      token = generate_token(jti: 'non-uuid-value')

      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidJtiError)
    end

    it 'verifies JTI claim value' do
      token = generate_token

      subject.verify_token(token)

      expect { subject.verify_token(token) }.to raise_error(JWT::InvalidJtiError)
    end

    it 'verifies OBO token presence' do
      obo = nil

      expect(upvs_token_authenticator).to receive(:verify_token).with(obo).and_call_original

      token = generate_token(obo: obo)

      expect { subject.verify_token(token) }.to raise_error(JWT::DecodeError)
    end

    it 'verifies OBO token format' do
      obo = 'NON-JWT'

      expect(upvs_token_authenticator).to receive(:verify_token).with(obo).and_call_original

      token = generate_token(obo: obo)

      expect { subject.verify_token(token) }.to raise_error(JWT::DecodeError)
    end

    it 'verifies OBO token value' do
      obo = generate_token

      expect(upvs_token_authenticator).to receive(:verify_token).with(obo).and_call_original

      token = generate_token(obo: obo)

      expect { subject.verify_token(token) }.to raise_error(JWT::DecodeError)
    end

    context 'token replay attacks' do
      it 'can not be verified twice in first 20 minutes' do
        token = generate_token

        subject.verify_token(token)

        travel_to Time.now + 20.minutes - 0.1.seconds

        expect { subject.verify_token(token) }.to raise_error(JWT::InvalidJtiError)
      end

      it 'can not be verified again on or after 20 minutes' do
        token = generate_token

        subject.verify_token(token)

        travel_to Time.now + 20.minutes

        expect { subject.verify_token(token) }.to raise_error(JWT::ExpiredSignature)
      end
    end

    context 'token decoder failure' do
      before(:example) { expect(JWT).to receive(:decode).with(any_args).and_raise(JWT::DecodeError) }

      it 'raises decode error' do
        expect { subject.verify_token(generate_token) }.to raise_error(JWT::DecodeError)
      end
    end
  end
end
