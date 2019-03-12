require 'rails_helper'

RSpec.describe ApiTokenAuthenticator do
  let(:key_pair) { OpenSSL::PKey::RSA.new(2048) }

  let(:identifier_store) { Environment.api_token_identifier_store }
  let(:public_key) { key_pair.public_key }
  let(:obo_token_authenticator) { Environment.obo_token_authenticator }

  let(:response) { OneLogin::RubySaml::Response.new(file_fixture('oam/sso_response_success.xml').read) }
  let(:assertion) { file_fixture('oam/sso_response_success_assertion.xml').read.strip }

  subject { described_class.new(identifier_store: identifier_store, public_key: public_key, obo_token_authenticator: obo_token_authenticator) }

  before(:example) { identifier_store.clear }

  before(:example) { travel_to '2018-11-28T20:26:16Z' }

  after(:example) { travel_back }

  describe '#invalidate_token' do
    pending
  end

  describe '#verify_token' do
    def generate_token(exp: 1543437976, jti: SecureRandom.uuid, obo: nil, header: {}, **payload)
      payload.merge!(exp: exp, jti: jti, obo: obo)
      JWT.encode(payload.compact, key_pair, 'RS256', header)
    end

    it 'returns nothing for tokens with TA key' do
      expect(subject.verify_token(generate_token, allow_ta: true)).to eq(nil)
    end

    it 'verifies format' do
      expect { subject.verify_token(nil, allow_ta: true) }.to raise_error(JWT::DecodeError)
      expect { subject.verify_token('NON-JWT', allow_ta: true) }.to raise_error(JWT::DecodeError)
    end

    it 'verifies algorithm' do
      token = JWT.encode(nil, 'KEY', 'HS256')

      expect { subject.verify_token(token, allow_ta: true) }.to raise_error(JWT::IncorrectAlgorithm)
    end

    it 'verifies signature' do
      token = JWT.encode(nil, OpenSSL::PKey::RSA.new(2048), 'RS256')

      expect { subject.verify_token(token, allow_ta: true) }.to raise_error(JWT::VerificationError)
    end

    it 'verifies CTY header absence' do
      token = generate_token(header: { cty: 'JWT' })

      expect { subject.verify_token(token, allow_ta: true) }.to raise_error(JWT::DecodeError)
    end

    it 'verifies EXP claim presence' do
      token = generate_token(exp: nil)

      expect { subject.verify_token(token, allow_ta: true) }.to raise_error(JWT::ExpiredSignature)
    end

    it 'verifies EXP claim format' do
      token = generate_token(exp: 'non-integer-value')

      expect { subject.verify_token(token, allow_ta: true) }.to raise_error(JWT::ExpiredSignature)
    end

    it 'verifies EXP claim value' do
      token = generate_token

      travel_to Time.now + 20.minutes

      expect { subject.verify_token(token, allow_ta: true) }.to raise_error(JWT::ExpiredSignature)
    end

    it 'verifies EXP claim to OBO token relation' do
      token = generate_token(exp: (Time.now + 120.minutes + 2.seconds).to_i)

      expect { subject.verify_token(token, allow_ta: true) }.to raise_error(JWT::InvalidPayload)
    end

    it 'verifies JTI claim presence' do
      token = generate_token(jti: nil)

      expect { subject.verify_token(token, allow_ta: true) }.to raise_error(JWT::InvalidJtiError)
    end

    it 'verifies JTI claim format' do
      token = generate_token(jti: '!')

      expect { subject.verify_token(token, allow_ta: true) }.to raise_error(JWT::InvalidJtiError)
    end

    it 'verifies JTI claim value' do
      token = generate_token

      subject.verify_token(token, allow_ta: true)

      expect { subject.verify_token(token, allow_ta: true) }.to raise_error(JWT::InvalidJtiError)
    end

    context 'with OBO token support' do
      it 'returns assertion for tokens with OBO token' do
        obo_token = obo_token_authenticator.generate_token(response)

        expect(obo_token_authenticator).to receive(:verify_token).with(obo_token, scope: nil).and_call_original

        token = generate_token(obo: obo_token, header: { cty: 'JWT' })

        expect(subject.verify_token(token, allow_obo: true)).to eq(assertion)
      end

      it 'verifies CTY header presence' do
        obo_token = obo_token_authenticator.generate_token(response)

        allow(obo_token_authenticator).to receive(:verify_token).with(obo_token, scope: nil).and_call_original

        token = generate_token(obo: obo_token, header: {})

        expect { subject.verify_token(token, allow_obo: true) }.to raise_error(JWT::InvalidPayload)
      end

      it 'verifies CTY header value' do
        obo_token = obo_token_authenticator.generate_token(response)

        allow(obo_token_authenticator).to receive(:verify_token).with(obo_token, scope: nil).and_call_original

        token = generate_token(obo: obo_token, header: { cty: 'NON-JWT' })

        expect { subject.verify_token(token, allow_obo: true) }.to raise_error(JWT::InvalidPayload)
      end

      it 'verifies OBO token presence' do
        obo_token = nil

        allow(obo_token_authenticator).to receive(:verify_token).with(obo_token, scope: nil).and_call_original

        token = generate_token(obo: obo_token, header: { cty: 'JWT' })

        expect { subject.verify_token(token, allow_obo: true) }.to raise_error(JWT::InvalidPayload)
      end

      it 'verifies OBO token format' do
        obo_token = 'NON-JWT'

        expect(obo_token_authenticator).to receive(:verify_token).with(obo_token, scope: nil).and_call_original

        token = generate_token(obo: obo_token, header: { cty: 'JWT' })

        expect { subject.verify_token(token, allow_obo: true) }.to raise_error(JWT::DecodeError)
      end

      it 'verifies OBO token value' do
        obo_token = generate_token

        expect(obo_token_authenticator).to receive(:verify_token).with(obo_token, scope: nil).and_call_original

        token = generate_token(obo: obo_token, header: { cty: 'JWT' })

        expect { subject.verify_token(token, allow_obo: true) }.to raise_error(JWT::VerificationError)
      end

      it 'verifies OBO token scope' do
        obo_token = obo_token_authenticator.generate_token(response, scopes: [])

        expect(obo_token_authenticator).to receive(:verify_token).with(obo_token, scope: 'sktalk/receive').and_call_original

        token = generate_token(obo: obo_token, header: { cty: 'JWT' })

        expect { subject.verify_token(token, allow_obo: true, require_obo_scope: 'sktalk/receive') }.to raise_error(JWT::VerificationError)
      end
    end

    context 'without OBO token support' do
      let(:obo_token_authenticator) { nil }

      it 'raises error for tokens with OBO token' do
        token = generate_token(obo: double, header: { cty: 'JWT' })

        expect { subject.verify_token(token, allow_obo: true) }.to raise_error(JWT::DecodeError)
      end
    end

    context 'token kind constraints' do
      let(:token_with_ta_key) { generate_token }
      let(:token_with_obo_token) { generate_token(obo: obo_token_authenticator.generate_token(response), header: { cty: 'JWT' }) }

      context 'allow both token kinds' do
        it 'returns nothing for tokens with TA key' do
          expect(subject.verify_token(token_with_ta_key, allow_ta: true, allow_obo: true)).to eq(nil)
        end

        it 'returns assertion for tokens with OBO token' do
          expect(subject.verify_token(token_with_obo_token, allow_ta: true, allow_obo: true)).to eq(assertion)
        end
      end

      context 'allow only tokens with TA key' do
        it 'returns nothing for tokens with TA key' do
          expect(subject.verify_token(token_with_ta_key, allow_ta: true, allow_obo: false)).to eq(nil)
        end

        it 'raises error for tokens with OBO token' do
          expect { subject.verify_token(token_with_obo_token, allow_ta: true, allow_obo: false) }.to raise_error(JWT::InvalidPayload)
        end
      end

      context 'allow only tokens with OBO token' do
        it 'raises error for tokens with TA key' do
          expect { subject.verify_token(token_with_ta_key, allow_ta: false, allow_obo: true) }.to raise_error(JWT::InvalidPayload)
        end

        it 'returns assertion for tokens with OBO token' do
          expect(subject.verify_token(token_with_obo_token, allow_ta: false, allow_obo: true)).to eq(assertion)
        end
      end

      context 'disallow both token kinds' do
        it 'raises error for tokens with TA key' do
          expect { subject.verify_token(token_with_ta_key, allow_ta: false, allow_obo: false) }.to raise_error(ArgumentError)
        end

        it 'raises error for tokens with OBO token' do
          expect { subject.verify_token(token_with_obo_token, allow_ta: false, allow_obo: false) }.to raise_error(ArgumentError)
        end
      end
    end

    context 'token scope constraints' do
      it 'ignores OBO token scope for tokens with TA key' do
        token = generate_token

        expect { subject.verify_token(token, allow_ta: true, allow_obo: true, require_obo_scope: 'sktalk/receive') }.not_to raise_error
      end

      it 'verifies OBO token scope for tokens with OBO token' do
        token = generate_token(obo: obo_token_authenticator.generate_token(response, scopes: ['sktalk/receive']), header: { cty: 'JWT' })

        expect { subject.verify_token(token, allow_obo: true, require_obo_scope: 'sktalk/receive') }.not_to raise_error
      end

      it 'raises error if OBO token scope is required but does not match given OBO token scope' do
        token = generate_token(obo: obo_token_authenticator.generate_token(response, scopes: []), header: { cty: 'JWT' })

        expect { subject.verify_token(token, allow_obo: true, require_obo_scope: 'sktalk/receive') }.to raise_error(JWT::VerificationError)
      end

      it 'raises error if OBO token scope is required but tokens with OBO token are not verifiable' do
        token = generate_token(obo: obo_token_authenticator.generate_token(response, scopes: ['sktalk/receive']), header: { cty: 'JWT' })

        expect { subject.verify_token(token, allow_obo: false, require_obo_scope: 'sktalk/receive') }.to raise_error(ArgumentError)
      end
    end

    context 'token replay attacks' do
      let(:obo_token_assertion_store) { Environment.obo_token_assertion_store }

      before(:example) { obo_token_assertion_store.clear }

      def generate_obo_token(exp: 1543437976, nbf: 1543436776)
        payload = { exp: exp, nbf: nbf, iat: nbf.to_f, jti: SecureRandom.uuid }
        obo_token_assertion_store.write(payload[:jti], assertion)
        JWT.encode(payload.compact, obo_token_key_pair, 'RS256')
      end

      it 'can not verify the same token twice in the first 20 minutes' do
        o1 = generate_obo_token
        t1 = generate_token(obo: o1, header: { cty: 'JWT' })

        subject.verify_token(t1, allow_obo: true)

        travel_to Time.now + 20.minutes - 0.1.seconds

        expect { subject.verify_token(t1, allow_obo: true) }.to raise_error(JWT::InvalidJtiError)
      end

      it 'can not verify the same token again on or after 20 minutes' do
        o1 = generate_obo_token
        t1 = generate_token(obo: o1, header: { cty: 'JWT' })

        subject.verify_token(t1, allow_obo: true)

        travel_to Time.now + 20.minutes

        expect { subject.verify_token(t1, allow_obo: true) }.to raise_error(JWT::ExpiredSignature)
      end

      it 'can not verify another token with the same JTI in the first 120 minutes' do
        jti = SecureRandom.uuid

        o1 = generate_obo_token(exp: (Time.now + 20.minutes).to_i, nbf: Time.now.to_i)
        t1 = generate_token(exp: (Time.now + 20.minutes).to_i, jti: jti, obo: o1, header: { cty: 'JWT' })

        subject.verify_token(t1, allow_obo: true)

        travel_to Time.now + 105.minutes

        o2 = generate_obo_token(exp: (Time.now + 20.minutes).to_i, nbf: Time.now.to_i)
        t2 = generate_token(exp: (Time.now + 20.minutes).to_i, jti: jti, obo: o2, header: { cty: 'JWT' })

        travel_to Time.now + 15.minutes - 0.1.seconds

        expect(identifier_store).to receive(:write).with(any_args).and_call_original

        expect { subject.verify_token(t2, allow_obo: true) }.to raise_error(JWT::InvalidJtiError)
      end

      it 'can verify another token with the same JTI again on or after 120 minutes' do
        jti = SecureRandom.uuid

        o1 = generate_obo_token(exp: (Time.now + 20.minutes).to_i, nbf: Time.now.to_i)
        t1 = generate_token(exp: (Time.now + 20.minutes).to_i, jti: jti, obo: o1, header: { cty: 'JWT' })

        subject.verify_token(t1, allow_obo: true)

        travel_to Time.now + 105.minutes

        o2 = generate_obo_token(exp: (Time.now + 20.minutes).to_i, nbf: Time.now.to_i)
        t2 = generate_token(exp: (Time.now + 20.minutes).to_i, jti: jti, obo: o2, header: { cty: 'JWT' })

        travel_to Time.now + 15.minutes

        expect(identifier_store).to receive(:write).with(any_args).and_return(true)

        expect { subject.verify_token(t2, allow_obo: true) }.not_to raise_error
      end
    end

    context 'token decoder failure' do
      before(:example) { expect(JWT).to receive(:decode).with(any_args).and_raise(JWT::DecodeError) }

      it 'raises decode error' do
        expect { subject.verify_token(generate_token, allow_ta: true) }.to raise_error(JWT::DecodeError)
      end
    end

    context 'JTI cache failure' do
      let(:identifier_store) { redis_cache_store_without_connection }

      it 'raises connection error' do
        expect { subject.verify_token(generate_token, allow_ta: true) }.to raise_error(Environment::RedisConnectionError)
      end
    end
  end
end
