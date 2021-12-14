require 'rails_helper'

RSpec.describe 'UPVS SSO' do
  def idp_response_object
    OmniAuth.config.mock_auth[:saml][:extra][:response_object]
  end

  def mock_idp_response(response)
    OmniAuth.config.add_mock(:saml, extra: { response_object: OneLogin::RubySaml::Response.new(response) })
  end

  before do
    ENV['LOGIN_CALLBACK_URL'] = 'http://login.dev'
    ENV['LOGOUT_CALLBACK_URL'] = 'http://logout.dev'
  end

  before(:example) do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:saml] = nil
  end

  after(:example) do
    OmniAuth.config.test_mode = false
  end

  let(:login_callback_url) { 'http://login.dev' }
  let(:logout_callback_url) { 'http://logout.dev' }

  context 'with UPVS SSO support', if: sso_support? do
    describe 'GET /auth/saml/login' do
      let(:callback) { 'http://localhost:3000' }

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

        it 'responds with 500' do
          post '/auth/saml/callback', params: { SAMLResponse: idp_response }

          expect(response.status).to eq(500)
        end
      end

      context 'with invalid response' do
        let(:idp_response) { 'INVALID' }

        before(:example) { mock_idp_response(idp_response) }

        it 'responds with 500' do
          post '/auth/saml/callback', params: { SAMLResponse: idp_response }

          expect(response.status).to eq(500)
        end
      end

      context 'with Success response' do
        let(:idp_response) { file_fixture('oam/sso_response_success.base64').read.strip }

        before(:example) { mock_idp_response(idp_response) }

        before(:example) { travel_to '2018-11-28T20:26:16Z' }

        it 'redirects to login callback location' do
          post '/auth/saml/callback', params: { SAMLResponse: idp_response }

          expect(response.status).to eq(302)
          expect(response.location).to start_with(login_callback_url + '?token=')
        end

        it 'generates OBO token with appropriate scopes' do
          authenticator = Environment.obo_token_authenticator
          scopes = Environment.obo_token_scopes

          expect(authenticator).to receive(:generate_token).with(idp_response_object, scopes: scopes).and_call_original

          post '/auth/saml/callback', params: { SAMLResponse: response }

          token = response.location.split('?token=').last

          expect(authenticator.verify_token(token)).to be
        end
      end

      context 'with Success response but later' do
        let(:idp_response) { file_fixture('oam/sso_response_success.base64').read.strip }

        before(:example) { mock_idp_response(idp_response) }

        before(:example) { travel_to '2018-11-28T21:26:16Z' }

        it 'responds with 500' do
          post '/auth/saml/callback', params: { SAMLResponse: idp_response }

          expect(response.status).to eq(500)
        end
      end

      context 'with NoAuthnContext response' do
        let(:idp_response) { file_fixture('oam/sso_response_no_authn_context.base64').read.strip }

        before(:example) { mock_idp_response(idp_response) }

        before(:example) { travel_to '2018-11-06T10:11:24Z' }

        it 'responds with 500' do
          post '/auth/saml/callback', params: { SAMLResponse: idp_response }

          expect(response.status).to eq(500)
        end
      end
    end

    describe 'GET /auth/saml/logout' do
      context 'IDP initiation' do
        let(:idp_request_query) { file_fixture('oam/slo_request.query').read.strip }

        before(:each) { allow_any_instance_of(ActionDispatch::Request).to receive(:host_with_port) { 'http://slovensko-sk-api.slovensko.digital' } }

        it 'redirects to IDP with response' do

          get '/auth/saml/logout' + idp_request_query

          expect(response.status).to eq(302)
          expect(response.location).to eq("#{logout_callback_url}?callback=http://slovensko-sk-api.slovensko.digital/auth/saml/slo#{idp_request_query}")
        end

        pending 'invalidates OBO token'
      end

      context 'SP initiation' do
        skip_upvs_subject_verification!

        before(:example) { travel_to '2018-11-28T20:26:16Z' }

        let(:token) { api_token_with_obo_token(file_fixture('oam/sso_response_success.xml').read) }

        it 'redirects to IDP with request' do
          get '/auth/saml/logout', headers: { 'Authorization' => 'Bearer ' + token }

          expect(response.status).to eq(302)
          expect(response.location).to end_with('/auth/saml/spslo')
        end

        it 'invalidates OBO token from given API token' do
          authenticator = Environment.api_token_authenticator

          expect(authenticator).to receive(:invalidate_token).with(token, allow_obo_token: true).and_call_original

          get '/auth/saml/logout', headers: { 'Authorization' => 'Bearer ' + token }

          expect { authenticator.verify_token(token, allow_obo_token: true) }.to raise_error(JWT::DecodeError)
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

        it 'allows authentication via tokens with CTY header + OBO token' do
          get '/auth/saml/logout', headers: { 'Authorization' => 'Bearer ' + api_token_with_obo_token(file_fixture('oam/sso_response_success.xml').read) }

          expect(response.status).to eq(302)
        end

        it 'responds with 400 if request does not contain any authentication' do
          get '/auth/saml/logout'

          expect(response.status).to eq(400)
          expect(response.object).to eq(message: 'No credentials')
        end

        it 'responds with 401 if authenticating via expired token' do
          # OBO tokens must be generated before any time travels, see authenticity tokens support
          token and travel_to 5.minutes.from_now

          get '/auth/saml/logout', headers: { 'Authorization' => 'Bearer ' + token }

          expect(response.status).to eq(401)
          expect(response.object).to eq(message: 'Bad credentials')
        end

        it 'responds with 401 if authenticating via token with SUB identifier' do
          get '/auth/saml/logout', headers: { 'Authorization' => 'Bearer ' + api_token_with_subject }

          expect(response.status).to eq(401)
          expect(response.object).to eq(message: 'Bad credentials')
        end

        context 'with response' do
          before(:example) { get '/auth/saml/logout', headers: { 'Authorization' => 'Bearer ' + token }}

          it 'redirects to internal action with logout callback location' do
            get '/auth/saml/logout', params: { SAMLResponse: 'RESPONSE' }

            expect(response.status).to eq(302)
            expect(response.location).to match(logout_callback_url.to_query('RelayState'))
          end
        end
      end
    end
  end

  context 'without UPVS SSO support', unless: sso_support? do
    describe 'GET /auth/saml/login' do
      it 'responds with 404' do
        get '/auth/saml/login'

        expect(response.status).to eq(404)
      end
    end

    describe 'POST /auth/saml/callback' do
      it 'responds with 404' do
        get '/auth/saml/callback'

        expect(response.status).to eq(404)
      end
    end

    describe 'GET /auth/saml/logout' do
      it 'responds with 404' do
        get '/auth/saml/logout'

        expect(response.status).to eq(404)
      end
    end
  end
end
