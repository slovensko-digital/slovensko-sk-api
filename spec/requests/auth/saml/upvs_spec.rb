require 'rails_helper'

RSpec.describe 'UPVS SAML Authentication' do
  def idp_response_object
    OmniAuth.config.mock_auth[:saml][:extra][:response_object]
  end

  def mock_idp_response(response)
    OmniAuth.config.add_mock(:saml, extra: { response_object: OneLogin::RubySaml::Response.new(response) })
  end

  before(:example) do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:saml] = nil
  end

  after(:example) do
    OmniAuth.config.test_mode = false
  end

  describe 'GET /auth/saml/login' do
    it 'redirects to IDP with request' do
      get '/auth/saml/login'

      follow_redirect!

      expect(response.status).to eq(302)
      expect(response.location).to end_with('/auth/saml/callback')
    end
  end

  describe 'POST /auth/saml/callback' do
    context 'with no response' do
      let(:idp_response) { nil }

      pending
    end

    context 'with any response' do
      let(:idp_response) { 'RESPONSE' }

      pending
    end

    context 'with Success response' do
      let(:idp_response) { file_fixture('oam/sso_response_success.base64').read.strip }

      before(:example) { mock_idp_response(idp_response) }

      before(:example) { travel_to '2018-11-28T20:26:16Z' }

      after(:example) { travel_back }

      it 'redirects to custom login callback location' do
        post '/auth/saml/callback', params: { SAMLResponse: idp_response }

        expect(response.status).to eq(302)
        expect(response.location).to start_with(Environment.login_callback_url + '?token=')
      end

      it 'generates OBO token with appropriate scopes' do
        authenticator = Environment.obo_token_authenticator

        scopes = ['sktalk/receive', 'sktalk/receive_and_save_to_outbox']

        expect(authenticator).to receive(:generate_token).with(idp_response_object, scopes: scopes).and_call_original

        post '/auth/saml/callback', params: { SAMLResponse: response }

        token = response.location.split('?token=').last

        expect(authenticator.verify_token(token)).to be
      end
    end

    context 'with Success response but later' do
      let(:idp_response) { file_fixture('oam/sso_response_success.base64').read.strip }

      before(:example) { travel_to '2018-11-28T21:26:16Z' }

      after(:example) { travel_back }

      pending
    end

    context 'with NoAuthnContext response' do
      let(:idp_response) { file_fixture('oam/sso_response_no_authn_context.base64').read.strip }

      before(:example) { travel_to '2018-11-06T10:11:24Z' }

      after(:example) { travel_back }

      pending
    end
  end

  describe 'GET /auth/saml/logout' do
    context 'IDP initiation' do
      let(:idp_request_query) { file_fixture('oam/slo_request.query').read.strip }

      it 'redirects to IDP with response' do
        get '/auth/saml/logout' + idp_request_query

        expect(response.status).to eq(302)
        expect(response.location).to end_with('/auth/saml/slo' + idp_request_query)
      end

      pending 'invalidates OBO token'
    end

    context 'SP initiation' do
      let!(:token) { api_token_with_obo_token_from_response(file_fixture('oam/sso_response_success.xml').read) }

      before(:example) { travel_to '2018-11-28T20:26:16Z' }

      after(:example) { travel_back }

      it 'redirects to IDP with request' do
        get '/auth/saml/logout', params: { token: token }

        expect(response.status).to eq(302)
        expect(response.location).to end_with('/auth/saml/spslo')
      end

      it 'invalidates OBO token from given API token' do
        authenticator = Environment.api_token_authenticator

        expect(authenticator).to receive(:invalidate_token).with(token, obo: true).and_call_original

        get '/auth/saml/logout', params: { token: token }

        expect { authenticator.verify_token(token, obo: true) }.to raise_error(JWT::DecodeError)
      end

      it 'supports authentication via headers' do
        get '/auth/saml/logout', headers: { 'Authorization' => 'Bearer ' + token }

        expect(response.status).to eq(302)
      end

      it 'supports authentication via parameters' do
        get '/auth/saml/logout', params: { token: token }

        expect(response.status).to eq(302)
      end

      it 'prefers authentication via headers over parameters' do
        get '/auth/saml/logout', headers: { 'Authorization' => 'Bearer ' + token }, params: { token: 'INVALID' }

        expect(response.status).to eq(302)
      end

      it 'responds with 400 if request does not contain any authentication' do
        get '/auth/saml/logout'

        expect(response.status).to eq(400)
        expect(response.body).to eq({ message: 'No credentials' }.to_json)
      end

      it 'responds with 401 if authentication does not pass' do
        travel_to Time.now + 20.minutes

        get '/auth/saml/logout', params: { token: token }

        expect(response.status).to eq(401)
        expect(response.body).to eq({ message: 'Bad credentials' }.to_json)
      end

      context 'with Success response' do
        pending 'processes IDP response' # slo_response_success.xml
      end

      context 'with Different User response' do
        pending 'processes IDP response' # slo_response_different_user.xml
      end
    end
  end
end
