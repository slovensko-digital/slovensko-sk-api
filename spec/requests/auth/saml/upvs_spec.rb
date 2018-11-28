require 'rails_helper'

RSpec.describe 'UPVS SAML Authentication' do
  describe 'GET /auth/saml/login' do
    it 'redirects to IDP with request' do
      get '/auth/saml/login'

      follow_redirect!

      expect(response.status).to eq(302)
      expect(response.location).to start_with('https://auth.vyvoj.upvs.globaltel.sk/oamfed/idp/samlv20?SAMLRequest=')
    end
  end

  describe 'POST /auth/saml/callback' do
    after(:example) { travel_back }

    context 'with no response' do
      let(:response) { nil }

      pending
    end

    context 'with any response' do
      let(:response) { 'RESPONSE' }

      pending
    end

    context 'with Success response' do
      let(:idp_response) { file_fixture('oam/response_success.base64').read }

      before(:example) { travel_to '2018-11-28T20:26:16Z' }

      it 'redirects to custom login callback location' do
        post '/auth/saml/callback', params: { SAMLResponse: idp_response }

        expect(response.status).to eq(302)
        expect(response.location).to start_with(ApiEnvironment.login_callback_url + '?token=')
      end
    end

    context 'with Success response but later' do
      let(:idp_response) { file_fixture('oam/response_success.base64').read }

      before(:example) { travel_to '2018-11-28T21:26:16Z' }

      pending
    end

    context 'with NoAuthnContext response' do
      let(:response) { file_fixture('oam/response_no_authn_context.base64').read }

      before(:example) { travel_to '2018-11-06T10:11:24Z' }

      pending
    end
  end

  describe 'GET /auth/saml/logout' do
    pending
  end
end
