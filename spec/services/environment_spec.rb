require 'rails_helper'

RSpec.describe Environment do
  subject { described_class }

  context 'with UPVS SSO support', if: sso_support? do
    describe '.obo_token_authenticator' do
      it 'returns OBO token authenticator' do
        expect(subject.obo_token_authenticator).to be_an(OboTokenAuthenticator)
      end
    end

    describe '.obo_token_assertion_store' do
      it 'returns Redis cache store' do
        expect(subject.obo_token_assertion_store).to be_a(ActiveSupport::Cache::RedisCacheStore)
      end
    end
  end

  context 'without UPVS SSO support', unless: sso_support? do
    describe '.obo_token_authenticator' do
      it 'returns nil' do
        expect(subject.obo_token_authenticator).to be_nil
      end
    end

    describe '.obo_token_assertion_store' do
      it 'returns nil' do
        expect(subject.obo_token_assertion_store).to be_nil
      end
    end
  end
end
