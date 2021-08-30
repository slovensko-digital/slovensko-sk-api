require 'rails_helper'

RSpec.describe ApiTokenAuthenticator do
  # time epsilon is set to 1 second by time helpers to prevent rounding errors with external services

  MAX_EXP_IN = described_class::MAX_EXP_IN

  let(:identifier_store) { redis_cache_store_in_ruby_memory }
  let(:public_key) { api_token_key_pair.public_key }
  let(:subject_verifier) { -> (sub) { sub == 'CIN-11190868' || sub == 'CIN-83130022' }}
  let(:obo_token_authenticator) { OboTokenAuthenticator.new(assertion_store: obo_token_assertion_store, key_pair: obo_token_key_pair, proxy_subject: obo_token_proxy_subject) }

  let(:obo_token_assertion) { file_fixture('oam/sso_response_success_assertion.xml').read.strip }
  let(:obo_token_assertion_store) { redis_cache_store_in_ruby_memory }
  let(:obo_token_proxy_subject) { 'CIN-83130022' }

  subject { described_class.new(identifier_store: identifier_store, public_key: public_key, subject_verifier: subject_verifier, obo_token_authenticator: obo_token_authenticator) }

  before(:example) { allow(JWT::ClaimsValidator).to receive_message_chain(:new, :validate!).with(any_args) }

  before(:example) { identifier_store.clear if identifier_store.respond_to?(:clear) }
  before(:example) { obo_token_assertion_store.clear if obo_token_assertion_store.respond_to?(:clear) }

  before(:example) { travel_to '2018-11-28T20:26:16Z' }

  delegate :now, to: Time

  def generate_token(sub: nil, exp: 1543437076, jti: SecureRandom.uuid, obo: nil, header: {}, **payload)
    payload.merge!(sub: sub, exp: exp, jti: jti, obo: obo)
    JWT.encode(payload.compact, api_token_key_pair, 'RS256', header)
  end

  def generate_obo_id
    SecureRandom.uuid
  end

  def generate_obo_token(exp: 1543437976, nbf: 1543436776, iat: 1543436776, jti: SecureRandom.uuid, header: {}, **payload)
    payload.merge!(exp: exp, nbf: nbf, iat: iat, jti: jti)
    obo_token_assertion_store.write(jti, obo_token_assertion) if obo_token_assertion_store.respond_to?(:write)
    JWT.encode(payload.compact, obo_token_key_pair, 'RS256', header)
  end

  describe '#invalidate_token' do
    pending
  end

  describe '#verify_token' do
    context 'with token constraints' do
      let(:token) { generate_token }
      let(:token_with_sub) { generate_token(sub: 'CIN-11190868') }
      let(:token_with_obo_id) { generate_token(sub: 'CIN-11190868', obo: generate_obo_id) }
      let(:token_with_obo_token) { generate_token(obo: generate_obo_token, header: { cty: 'JWT' }) }

      context 'allow all token types' do
        it 'returns nil and nil for tokens with no identity' do
          expect(subject.verify_token(token, allow_plain: true, allow_sub: true, allow_obo_token: true)).to eq([nil, nil])
        end

        it 'returns SUB claim and nil for tokens with SUB identifier' do
          expect(subject.verify_token(token_with_sub, allow_plain: true, allow_sub: true, allow_obo_token: true)).to eq(['CIN-11190868', nil])
        end

        pending 'returns SUB claim and OBO identifier for tokens with SUB identifier + OBO identifier'

        it 'returns SUB proxy and OBO assertion for tokens with CTY header + OBO token' do
          expect(subject.verify_token(token_with_obo_token, allow_plain: true, allow_sub: true, allow_obo_token: true)).to eq([obo_token_proxy_subject, obo_token_assertion])
        end

        context 'without OBO token support' do
          let(:obo_token_authenticator) { nil }

          it 'raises error for tokens with CTY header + OBO token' do
            expect { subject.verify_token(token_with_obo_token, allow_plain: true, allow_sub: true, allow_obo_token: true) }.to raise_error(JWT::DecodeError)
          end
        end
      end

      context 'allow only tokens with no identity' do
        it 'returns nil and nil for tokens with no identity' do
          expect(subject.verify_token(token, allow_plain: true)).to eq([nil, nil])
        end

        it 'raises error for tokens with SUB identifier' do
          expect { subject.verify_token(token_with_sub, allow_plain: true) }.to raise_error(JWT::InvalidPayload)
        end

        it 'raises error for tokens with SUB identifier + OBO identifier' do
          expect { subject.verify_token(token_with_obo_id, allow_plain: true) }.to raise_error(JWT::InvalidPayload)
        end

        it 'raises error for tokens with CTY header + OBO token' do
          expect { subject.verify_token(token_with_obo_token, allow_plain: true) }.to raise_error(JWT::InvalidPayload)
        end

        context 'without OBO token support' do
          it 'raises error for tokens with CTY header + OBO token' do
            expect { subject.verify_token(token_with_obo_token, allow_plain: true) }.to raise_error(JWT::DecodeError)
          end
        end
      end

      context 'allow only tokens with SUB identifier' do
        it 'raises error for tokens with no identity' do
          expect { subject.verify_token(token, allow_sub: true) }.to raise_error(JWT::InvalidSubError)
        end

        it 'returns SUB claim and nil for tokens with SUB identifier' do
          expect(subject.verify_token(token_with_sub, allow_sub: true)).to eq(['CIN-11190868', nil])
        end

        it 'raises error for tokens with SUB identifier + OBO identifier' do
          expect { subject.verify_token(token_with_obo_id, allow_sub: true) }.to raise_error(JWT::InvalidPayload)
        end

        it 'raises error for tokens with CTY header + OBO token' do
          expect { subject.verify_token(token_with_obo_token, allow_sub: true) }.to raise_error(JWT::InvalidPayload)
        end

        context 'without OBO token support' do
          it 'raises error for tokens with CTY header + OBO token' do
            expect { subject.verify_token(token_with_obo_token, allow_sub: true) }.to raise_error(JWT::DecodeError)
          end
        end
      end

      context 'allow only tokens with SUB identifier + OBO identifier' do
        pending 'raises error for tokens with no identity'

        pending 'raises error for tokens with SUB identifier'

        pending 'returns SUB claim and OBO identifier for tokens with SUB identifier + OBO identifier'

        pending 'raises error for tokens with CTY header + OBO token'

        context 'without OBO token support' do
          pending 'raises error for tokens with CTY header + OBO token'
        end
      end

      context 'allow only tokens with CTY header + OBO token' do
        it 'raises error for tokens with no identity' do
          expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidPayload)
        end

        it 'raises error for tokens with SUB identifier' do
          expect { subject.verify_token(token_with_sub, allow_obo_token: true) }.to raise_error(JWT::InvalidPayload)
        end

        it 'raises error for tokens with SUB identifier + OBO identifier' do
          expect { subject.verify_token(token_with_obo_id, allow_obo_token: true) }.to raise_error(JWT::InvalidPayload)
        end

        it 'returns SUB proxy and OBO assertion for tokens with CTY header + OBO token' do
          expect(subject.verify_token(token_with_obo_token, allow_obo_token: true)).to eq([obo_token_proxy_subject, obo_token_assertion])
        end

        context 'without OBO token support' do
          let(:obo_token_authenticator) { nil }

          it 'raises error for tokens with CTY header + OBO token' do
            expect { subject.verify_token(token_with_obo_token, allow_obo_token: true) }.to raise_error(JWT::DecodeError)
          end
        end
      end

      context 'disallow all token types' do
        it 'raises error for tokens with no identity' do
          expect { subject.verify_token(token) }.to raise_error(ArgumentError)
        end

        it 'raises error for tokens with SUB identifier' do
          expect { subject.verify_token(token_with_sub) }.to raise_error(ArgumentError)
        end

        it 'raises error for tokens with SUB identifier + OBO identifier' do
          expect { subject.verify_token(token_with_obo_id) }.to raise_error(ArgumentError)
        end

        it 'raises error for tokens with CTY header + OBO token' do
          expect { subject.verify_token(token_with_obo_token) }.to raise_error(ArgumentError)
        end

        context 'without OBO token support' do
          it 'raises error for tokens with CTY header + OBO token' do
            expect { subject.verify_token(token_with_obo_token) }.to raise_error(ArgumentError)
          end
        end
      end
    end

    context 'with no identity constraint' do
      def generate_token(**payload)
        super
      end

      it 'returns nil and nil' do
        token = generate_token
        expect(subject.verify_token(token, allow_plain: true)).to eq([nil, nil])
      end

      it 'verifies format' do
        expect { subject.verify_token(nil, allow_plain: true) }.to raise_error(JWT::DecodeError)
        expect { subject.verify_token('?', allow_plain: true) }.to raise_error(JWT::DecodeError)
      end

      it 'verifies algorithm' do
        token = JWT.encode(nil, 'KEY', 'HS256')
        expect { subject.verify_token(token, allow_plain: true) }.to raise_error(JWT::IncorrectAlgorithm)
      end

      it 'verifies signature' do
        token = JWT.encode(nil, OpenSSL::PKey::RSA.new(2048), 'RS256')
        expect { subject.verify_token(token, allow_plain: true) }.to raise_error(JWT::VerificationError)
      end

      it 'verifies CTY header absence' do
        token = generate_token(header: { cty: 'JWT' })
        expect { subject.verify_token(token, allow_plain: true) }.to raise_error(JWT::InvalidPayload)
      end

      it 'verifies SUB claim absence' do
        token = generate_token(sub: 'CIN-11190868')
        expect { subject.verify_token(token, allow_plain: true) }.to raise_error(JWT::InvalidPayload)
      end

      it 'verifies EXP claim presence' do
        token = generate_token(exp: nil)
        expect { subject.verify_token(token, allow_plain: true) }.to raise_error(JWT::InvalidPayload, 'exp')
      end

      it 'verifies EXP claim format' do
        token = generate_token(exp: '?')
        expect { subject.verify_token(token, allow_plain: true) }.to raise_error(JWT::InvalidPayload, 'exp')
      end

      it 'verifies EXP claim value (expired in the past)' do
        token = generate_token(exp: 1.second.ago.to_i)
        expect { subject.verify_token(token, allow_plain: true) }.to raise_error(JWT::ExpiredSignature, 'exp')
      end

      it 'verifies EXP claim value (expired now)' do
        token = generate_token(exp: now.to_i)
        expect { subject.verify_token(token, allow_plain: true) }.to raise_error(JWT::ExpiredSignature, 'exp')
      end

      it 'verifies EXP claim value (expired in the future)' do
        token = generate_token(exp: 1.second.from_now.to_i)
        subject.verify_token(token, allow_plain: true)
      end

      it 'verifies EXP claim value (expired in the far future)' do
        token = generate_token(exp: (MAX_EXP_IN + 1.second).from_now.to_i)
        expect { subject.verify_token(token, allow_plain: true) }.to raise_error(JWT::InvalidPayload, 'exp')
      end

      it 'verifies JTI claim presence' do
        token = generate_token(jti: nil)
        expect { subject.verify_token(token, allow_plain: true) }.to raise_error(JWT::InvalidJtiError)
      end

      it 'verifies JTI claim format' do
        token = generate_token(jti: '?')
        expect { subject.verify_token(token, allow_plain: true) }.to raise_error(JWT::InvalidJtiError)
      end

      it 'verifies JTI claim value' do
        token = generate_token
        subject.verify_token(token, allow_plain: true)
        expect { subject.verify_token(token, allow_plain: true) }.to raise_error(JWT::InvalidJtiError)
      end

      it 'verifies OBO claim absence' do
        token = generate_token(obo: generate_obo_token)
        expect { subject.verify_token(token, allow_plain: true) }.to raise_error(JWT::InvalidPayload)
      end

      context 'token replay attacks' do
        it 'can not verify the same token twice in the first 5 minutes' do
          t1 = generate_token(exp: MAX_EXP_IN.from_now.to_i)
          subject.verify_token(t1, allow_plain: true)

          travel_to MAX_EXP_IN.from_now - 1.second

          expect { subject.verify_token(t1, allow_plain: true) }.to raise_error(JWT::InvalidJtiError)
        end

        it 'can not verify another token with the same JTI in the first 5 minutes' do
          jti = SecureRandom.uuid
          t1 = generate_token(exp: MAX_EXP_IN.from_now.to_i, jti: jti)
          subject.verify_token(t1, allow_plain: true)

          travel_to MAX_EXP_IN.from_now - 1.second

          t2 = generate_token(exp: MAX_EXP_IN.from_now.to_i, jti: jti)
          expect { subject.verify_token(t2, allow_plain: true) }.to raise_error(JWT::InvalidJtiError)
        end

        it 'can verify another token with the same JTI on or after 5 minutes' do
          jti = SecureRandom.uuid
          t1 = generate_token(exp: MAX_EXP_IN.from_now.to_i, jti: jti)
          subject.verify_token(t1, allow_plain: true)

          travel_to MAX_EXP_IN.from_now

          t2 = generate_token(exp: MAX_EXP_IN.from_now.to_i, jti: jti)
          expect { subject.verify_token(t2, allow_plain: true) }.not_to raise_error
        end
      end

      context 'token decoder failure' do
        let(:subject_verifier) { double(:unreachable) }
        let(:identifier_store) { double(:unreachable) }

        before(:example) { expect(JWT).to receive(:decode).and_raise(JWT::DecodeError) }

        it 'raises error' do
          expect { subject.verify_token(generate_token, allow_plain: true) }.to raise_error(JWT::DecodeError)
        end
      end

      context 'identifier store failure' do
        let(:subject_verifier) { double(:unreachable) }
        let(:identifier_store) { redis_cache_store_without_connection }

        it 'raises error' do
          expect { subject.verify_token(generate_token, allow_plain: true) }.to raise_error(Environment::RedisConnectionError)
        end
      end
    end

    context 'with SUB identifier constraint' do
      def generate_token(sub: 'CIN-11190868', **payload)
        super
      end

      it 'returns SUB claim and nil' do
        token = generate_token(sub: 'CIN-11190868')
        expect(subject.verify_token(token, allow_sub: true)).to eq(['CIN-11190868', nil])
      end

      it 'verifies format' do
        expect { subject.verify_token(nil, allow_sub: true) }.to raise_error(JWT::DecodeError)
        expect { subject.verify_token('?', allow_sub: true) }.to raise_error(JWT::DecodeError)
      end

      it 'verifies algorithm' do
        token = JWT.encode(nil, 'KEY', 'HS256')
        expect { subject.verify_token(token, allow_sub: true) }.to raise_error(JWT::IncorrectAlgorithm)
      end

      it 'verifies signature' do
        token = JWT.encode(nil, OpenSSL::PKey::RSA.new(2048), 'RS256')
        expect { subject.verify_token(token, allow_sub: true) }.to raise_error(JWT::VerificationError)
      end

      it 'verifies CTY header absence' do
        token = generate_token(header: { cty: 'JWT' })
        expect { subject.verify_token(token, allow_sub: true) }.to raise_error(JWT::InvalidPayload)
      end

      it 'verifies SUB claim presence' do
        token = generate_token(sub: nil)
        expect { subject.verify_token(token, allow_sub: true) }.to raise_error(JWT::InvalidSubError)
      end

      it 'verifies SUB claim value' do
        token = generate_token(sub: 'CIN-00000000')
        expect { subject.verify_token(token, allow_sub: true) }.to raise_error(JWT::InvalidSubError)
      end

      it 'verifies EXP claim presence' do
        token = generate_token(exp: nil)
        expect { subject.verify_token(token, allow_sub: true) }.to raise_error(JWT::InvalidPayload, 'exp')
      end

      it 'verifies EXP claim format' do
        token = generate_token(exp: '?')
        expect { subject.verify_token(token, allow_sub: true) }.to raise_error(JWT::InvalidPayload, 'exp')
      end

      it 'verifies EXP claim value (expired in the past)' do
        token = generate_token(exp: 1.second.ago.to_i)
        expect { subject.verify_token(token, allow_sub: true) }.to raise_error(JWT::ExpiredSignature, 'exp')
      end

      it 'verifies EXP claim value (expired now)' do
        token = generate_token(exp: now.to_i)
        expect { subject.verify_token(token, allow_sub: true) }.to raise_error(JWT::ExpiredSignature, 'exp')
      end

      it 'verifies EXP claim value (expired in the future)' do
        token = generate_token(exp: 1.second.from_now.to_i)
        subject.verify_token(token, allow_sub: true)
      end

      it 'verifies EXP claim value (expired in the far future)' do
        token = generate_token(exp: (MAX_EXP_IN + 1.second).from_now.to_i)
        expect { subject.verify_token(token, allow_sub: true) }.to raise_error(JWT::InvalidPayload, 'exp')
      end

      it 'verifies JTI claim presence' do
        token = generate_token(jti: nil)
        expect { subject.verify_token(token, allow_sub: true) }.to raise_error(JWT::InvalidJtiError)
      end

      it 'verifies JTI claim format' do
        token = generate_token(jti: '?')
        expect { subject.verify_token(token, allow_sub: true) }.to raise_error(JWT::InvalidJtiError)
      end

      it 'verifies JTI claim value' do
        token = generate_token
        subject.verify_token(token, allow_sub: true)
        expect { subject.verify_token(token, allow_sub: true) }.to raise_error(JWT::InvalidJtiError)
      end

      it 'verifies OBO claim absence' do
        token = generate_token(obo: generate_obo_token)
        expect { subject.verify_token(token, allow_sub: true) }.to raise_error(JWT::InvalidPayload)
      end

      context 'token replay attacks' do
        it 'can not verify the same token twice in the first 5 minutes' do
          t1 = generate_token(exp: MAX_EXP_IN.from_now.to_i)
          subject.verify_token(t1, allow_sub: true)

          travel_to MAX_EXP_IN.from_now - 1.second

          expect { subject.verify_token(t1, allow_sub: true) }.to raise_error(JWT::InvalidJtiError)
        end

        it 'can not verify another token with the same JTI and SUB claims in the first 5 minutes' do
          jti = SecureRandom.uuid
          t1 = generate_token(sub: 'CIN-11190868', exp: MAX_EXP_IN.from_now.to_i, jti: jti)
          subject.verify_token(t1, allow_sub: true)

          travel_to MAX_EXP_IN.from_now - 1.second

          t2 = generate_token(sub: 'CIN-11190868', exp: MAX_EXP_IN.from_now.to_i, jti: jti)
          expect { subject.verify_token(t2, allow_sub: true) }.to raise_error(JWT::InvalidJtiError)
        end

        it 'can verify another token with the same JTI and SUB claims on or after 5 minutes' do
          jti = SecureRandom.uuid
          t1 = generate_token(sub: 'CIN-11190868', exp: MAX_EXP_IN.from_now.to_i, jti: jti)
          subject.verify_token(t1, allow_sub: true)

          travel_to MAX_EXP_IN.from_now

          t2 = generate_token(sub: 'CIN-11190868', exp: MAX_EXP_IN.from_now.to_i, jti: jti)
          expect { subject.verify_token(t2, allow_sub: true) }.not_to raise_error
        end

        it 'can verify another token with the same JTI claim but different SUB claim in the first 5 minutes' do
          jti = SecureRandom.uuid
          t1 = generate_token(sub: 'CIN-11190868', exp: MAX_EXP_IN.from_now.to_i, jti: jti)
          subject.verify_token(t1, allow_sub: true)

          travel_to MAX_EXP_IN.from_now - 1.second

          t2 = generate_token(sub: 'CIN-83130022', exp: MAX_EXP_IN.from_now.to_i, jti: jti)
          expect { subject.verify_token(t2, allow_sub: true) }.not_to raise_error
        end

        it 'can verify another token with the same JTI claim but different SUB claim on or after 5 minutes' do
          jti = SecureRandom.uuid
          t1 = generate_token(sub: 'CIN-11190868', exp: MAX_EXP_IN.from_now.to_i, jti: jti)
          subject.verify_token(t1, allow_sub: true)

          travel_to MAX_EXP_IN.from_now

          t2 = generate_token(sub: 'CIN-83130022', exp: MAX_EXP_IN.from_now.to_i, jti: jti)
          expect { subject.verify_token(t2, allow_sub: true) }.not_to raise_error
        end
      end

      context 'token decoder failure' do
        let(:subject_verifier) { double(:unreachable) }
        let(:identifier_store) { double(:unreachable) }

        before(:example) { expect(JWT).to receive(:decode).and_raise(JWT::DecodeError) }

        it 'raises error' do
          expect { subject.verify_token(generate_token, allow_sub: true) }.to raise_error(JWT::DecodeError)
        end
      end

      context 'subject verifier failure' do
        let(:subject_verifier) { double.tap { |o| expect(o).to receive(:call).and_raise(RuntimeError) }}
        let(:identifier_store) { double(:unreachable) }

        it 'raises error' do
          expect { subject.verify_token(generate_token, allow_sub: true) }.to raise_error(RuntimeError)
        end
      end

      context 'identifier store failure' do
        let(:identifier_store) { redis_cache_store_without_connection }

        it 'raises error' do
          expect { subject.verify_token(generate_token, allow_sub: true) }.to raise_error(Environment::RedisConnectionError)
        end
      end
    end

    context 'with SUB identifier + OBO identifier constraint' do
      def generate_token(sub: 'CIN-11190868', obo: generate_obo_id, **payload)
        super
      end

      pending

      context 'OBO identifier' do
        pending
      end

      context 'token replay attacks' do
        pending
      end

      context 'token decoder failure' do
        pending
      end

      context 'subject verifier failure' do
        pending
      end

      context 'identifier store failure' do
        pending
      end
    end

    context 'with CTY header + OBO token constraint' do
      def generate_token(obo: generate_obo_token, header: { cty: 'JWT' }, **payload)
        super
      end

      it 'returns SUB proxy and OBO assertion' do
        token = generate_token
        expect(subject.verify_token(token, allow_obo_token: true)).to eq([obo_token_proxy_subject, obo_token_assertion])
      end

      it 'verifies format' do
        expect { subject.verify_token(nil, allow_obo_token: true) }.to raise_error(JWT::DecodeError)
        expect { subject.verify_token('?', allow_obo_token: true) }.to raise_error(JWT::DecodeError)
      end

      it 'verifies algorithm' do
        token = JWT.encode(nil, 'KEY', 'HS256')
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::IncorrectAlgorithm)
      end

      it 'verifies signature' do
        token = JWT.encode(nil, OpenSSL::PKey::RSA.new(2048), 'RS256')
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::VerificationError)
      end

      it 'verifies CTY header presence' do
        token = generate_token(header: {})
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidPayload)
      end

      it 'verifies CTY header value' do
        token = generate_token(header: { cty: '?' })
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidPayload)
      end

      it 'verifies SUB claim absence' do
        token = generate_token(sub: 'CIN-11190868')
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidPayload)
      end

      it 'verifies EXP claim presence' do
        token = generate_token(exp: nil)
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidPayload, 'exp')
      end

      it 'verifies EXP claim format' do
        token = generate_token(exp: '?')
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidPayload, 'exp')
      end

      it 'verifies EXP claim value (expired in the past)' do
        token = generate_token(exp: 1.second.ago.to_i)
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::ExpiredSignature, 'exp')
      end

      it 'verifies EXP claim value (expired now)' do
        token = generate_token(exp: now.to_i)
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::ExpiredSignature, 'exp')
      end

      it 'verifies EXP claim value (expired in the future)' do
        token = generate_token(exp: 1.second.from_now.to_i)
        subject.verify_token(token, allow_obo_token: true)
      end

      it 'verifies EXP claim value (expired in the far future)' do
        token = generate_token(exp: (MAX_EXP_IN + 1.second).from_now.to_i)
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidPayload, 'exp')
      end

      it 'verifies JTI claim presence' do
        token = generate_token(jti: nil)
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidJtiError)
      end

      it 'verifies JTI claim format' do
        token = generate_token(jti: '?')
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidJtiError)
      end

      it 'verifies JTI claim value' do
        token = generate_token
        subject.verify_token(token, allow_obo_token: true)
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidJtiError)
      end

      it 'verifies OBO claim presence' do
        token = generate_token(obo: nil)
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidPayload)
      end

      it 'verifies OBO claim format' do
        token = generate_token(obo: '?')
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidPayload, 'obo')
      end

      it 'verifies OBO claim value' do
        token = generate_token(obo: generate_obo_token(exp: 1.second.ago.to_i))
        expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidPayload, 'obo')
      end

      context 'OBO token' do
        it 'verifies OBO token' do
          obo_token = generate_obo_token(exp: 1.second.ago.to_i)
          token = generate_token(obo: obo_token)
          expect(obo_token_authenticator).to receive(:verify_token).with(obo_token, scope: nil).and_call_original
          expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidPayload, 'obo') do |error|
            expect { raise error.cause }.to raise_error(JWT::ExpiredSignature, 'exp')
          end
        end

        it 'verifies OBO token scope if given' do
          obo_token = generate_obo_token(scopes: ['edesk/authorize'])
          token = generate_token(obo: obo_token)
          expect(obo_token_authenticator).to receive(:verify_token).with(obo_token, scope: 'sktalk/receive').and_call_original
          expect { subject.verify_token(token, allow_obo_token: true, require_obo_token_scope: 'sktalk/receive') }.to raise_error(JWT::InvalidPayload, 'obo') do |error|
            expect { raise error.cause }.to raise_error(JWT::InvalidPayload, 'scope')
          end
        end
      end

      context 'SUB proxy' do
        it 'verifies SUB proxy presence' do
          token = generate_token
          expect(obo_token_authenticator).to receive(:verify_token).and_return([nil, obo_token_assertion])
          expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidSubError, 'obo')
        end

        it 'verifies SUB proxy value' do
          token = generate_token
          expect(obo_token_authenticator).to receive(:verify_token).and_return(['CIN-00000000', obo_token_assertion])
          expect { subject.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::InvalidSubError, 'obo')
        end
      end

      context 'token replay attacks' do
        it 'can not verify the same token twice in the first 5 minutes' do
          o1 = generate_obo_token(exp: MAX_EXP_IN.from_now.to_i, nbf: now.to_i)
          t1 = generate_token(exp: MAX_EXP_IN.from_now.to_i, obo: o1)
          subject.verify_token(t1, allow_obo_token: true)

          travel_to MAX_EXP_IN.from_now - 1.second

          expect { subject.verify_token(t1, allow_obo_token: true) }.to raise_error(JWT::InvalidJtiError)
        end

        it 'can not verify another token with the same JTI claim in the first 5 minutes' do
          jti = SecureRandom.uuid
          o1 = generate_obo_token(exp: MAX_EXP_IN.from_now.to_i, nbf: now.to_i, iat: now.to_i)
          t1 = generate_token(exp: MAX_EXP_IN.from_now.to_i, jti: jti, obo: o1)
          subject.verify_token(t1, allow_obo_token: true)

          travel_to MAX_EXP_IN.from_now - 1.second

          o2 = generate_obo_token(exp: MAX_EXP_IN.from_now.to_i, nbf: now.to_i, iat: now.to_i)
          t2 = generate_token(exp: MAX_EXP_IN.from_now.to_i, jti: jti, obo: o2)
          expect { subject.verify_token(t2, allow_obo_token: true) }.to raise_error(JWT::InvalidJtiError)
        end

        it 'can verify another token with the same JTI claim on or after 5 minutes' do
          jti = SecureRandom.uuid
          o1 = generate_obo_token(exp: 20.minutes.from_now.to_i, nbf: now.to_i, iat: now.to_i)
          t1 = generate_token(exp: MAX_EXP_IN.from_now.to_i, jti: jti, obo: o1)
          subject.verify_token(t1, allow_obo_token: true)

          travel_to MAX_EXP_IN.from_now

          o2 = generate_obo_token(exp: 20.minutes.from_now.to_i, nbf: now.to_i, iat: now.to_i)
          t2 = generate_token(exp: MAX_EXP_IN.from_now.to_i, jti: jti, obo: o2)
          expect { subject.verify_token(t2, allow_obo_token: true) }.not_to raise_error
        end
      end

      context 'token decoder failure' do
        let(:obo_token_authenticator) { double(:unreachable) }
        let(:obo_token_assertion_store) { double(:unreachable) }
        let(:subject_verifier) { double(:unreachable) }
        let(:identifier_store) { double(:unreachable) }

        before(:example) { expect(JWT).to receive(:decode).and_raise(JWT::DecodeError) }

        it 'raises error' do
          expect { subject.verify_token(generate_token, allow_obo_token: true) }.to raise_error(JWT::DecodeError)
        end
      end

      context 'OBO token authenticator failure' do
        let(:obo_token_authenticator) { double.tap { |o| expect(o).to receive(:verify_token).and_raise(RuntimeError) }}
        let(:obo_token_assertion_store) { double(:unreachable) }
        let(:subject_verifier) { double(:unreachable) }
        let(:identifier_store) { double(:unreachable) }

        it 'raises error' do
          expect { subject.verify_token(generate_token, allow_obo_token: true) }.to raise_error(RuntimeError)
        end
      end

      context 'OBO token assertion store failure' do
        let(:obo_token_assertion_store) { redis_cache_store_without_connection }
        let(:subject_verifier) { double(:unreachable) }
        let(:identifier_store) { double(:unreachable) }

        it 'raises error' do
          expect { subject.verify_token(generate_token, allow_obo_token: true) }.to raise_error(Environment::RedisConnectionError)
        end
      end

      context 'subject verifier failure' do
        let(:subject_verifier) { double.tap { |o| expect(o).to receive(:call).and_raise(RuntimeError) }}
        let(:identifier_store) { double(:unreachable) }

        it 'raises error' do
          expect { subject.verify_token(generate_token, allow_obo_token: true) }.to raise_error(RuntimeError)
        end
      end

      context 'identifier store failure' do
        let(:identifier_store) { redis_cache_store_without_connection }

        it 'raises error' do
          expect { subject.verify_token(generate_token, allow_obo_token: true) }.to raise_error(Environment::RedisConnectionError)
        end
      end
    end
  end
end
