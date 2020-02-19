require 'rails_helper'

RSpec.describe 'UPVS API' do
  context 'with UPVS SSO support', sso: true do
    before(:example) { travel_to '2018-11-28T20:26:16Z' }

    let!(:token) { api_token_with_obo_token_from_response(file_fixture('oam/sso_response_success.xml').read) }

    before(:example) { allow(UpvsProxy).to receive(:new).and_wrap_original { double }}

    after(:example) { travel_back }

    describe 'GET /api/upvs/user/info' do
      before(:example) do
        allow_any_instance_of(IamRepository).to receive(:identity).with('rc://sk/8314451337_tisici_janko').and_return(iam_get_identity_response('iam/get_identity/with_details_response.xml').identity_data)
      end

      it 'returns UPVS identity' do
        get '/api/upvs/user/info', headers: { 'Authorization' => 'Bearer ' + token }

        expect(response.status).to eq(200)
        expect(response.object).to eq(JSON.parse(file_fixture('api/upvs/info.json').read, symbolize_names: true))

        expect(response.content_type).to eq('application/json')
        expect(response.charset).to eq('utf-8')
      end

      it 'supports authentication via headers' do
        get '/api/upvs/user/info', headers: { 'Authorization' => 'Bearer ' + token }

        expect(response.status).to eq(200)
      end

      it 'supports authentication via parameters' do
        get '/api/upvs/user/info', params: { token: token }

        expect(response.status).to eq(200)
      end

      it 'prefers authentication via headers over parameters' do
        get '/api/upvs/user/info', headers: { 'Authorization' => 'Bearer ' + token }, params: { token: 'INVALID' }

        expect(response.status).to eq(200)
      end

      it 'allows authentication via tokens with OBO token' do
        get '/api/upvs/user/info', headers: { 'Authorization' => 'Bearer ' + api_token_with_obo_token_from_response(file_fixture('oam/sso_response_success.xml').read) }

        expect(response.status).to eq(200)
      end

      it 'responds with 400 if request does not contain any authentication' do
        get '/api/upvs/user/info'

        expect(response.status).to eq(400)
        expect(response.body).to eq({ message: 'No credentials' }.to_json)
      end

      it 'responds with 401 if authenticating via expired token' do
        travel_to Time.now + 20.minutes

        get '/api/upvs/user/info', headers: { 'Authorization' => 'Bearer ' + token }

        expect(response.status).to eq(401)
        expect(response.body).to eq({ message: 'Bad credentials' }.to_json)
      end

      it 'responds with 401 if authenticating via token with TA key' do
        get '/api/upvs/user/info', headers: { 'Authorization' => 'Bearer ' + api_token_with_ta_key }

        expect(response.status).to eq(401)
        expect(response.body).to eq({ message: 'Bad credentials' }.to_json)
      end

      pending 'responds with 500 if anything else fails'
    end

    describe 'GET /api/upvs/user/info.saml' do
      let(:assertion) { file_fixture('oam/sso_response_success_assertion.xml').read.strip }

      it 'returns SAML assertion' do
        get '/api/upvs/user/info.saml', headers: { 'Authorization' => 'Bearer ' + token }

        expect(response.status).to eq(200)
        expect(response.body).to eq(assertion)

        expect(response.content_type).to eq('application/samlassertion+xml')
        expect(response.charset).to eq('utf-8')
      end

      it 'supports authentication via headers' do
        get '/api/upvs/user/info.saml', headers: { 'Authorization' => 'Bearer ' + token }

        expect(response.status).to eq(200)
      end

      it 'supports authentication via parameters' do
        get '/api/upvs/user/info.saml', params: { token: token }

        expect(response.status).to eq(200)
      end

      it 'prefers authentication via headers over parameters' do
        get '/api/upvs/user/info.saml', headers: { 'Authorization' => 'Bearer ' + token }, params: { token: 'INVALID' }

        expect(response.status).to eq(200)
      end

      it 'allows authentication via tokens with OBO token' do
        get '/api/upvs/user/info.saml', headers: { 'Authorization' => 'Bearer ' + api_token_with_obo_token_from_response(file_fixture('oam/sso_response_success.xml').read) }

        expect(response.status).to eq(200)
      end

      it 'responds with 400 if request does not contain any authentication' do
        get '/api/upvs/user/info.saml'

        expect(response.status).to eq(400)
        expect(response.body).to eq({ message: 'No credentials' }.to_json)
      end

      it 'responds with 401 if authenticating via expired token' do
        travel_to Time.now + 20.minutes

        get '/api/upvs/user/info.saml', headers: { 'Authorization' => 'Bearer ' + token }

        expect(response.status).to eq(401)
        expect(response.body).to eq({ message: 'Bad credentials' }.to_json)
      end

      it 'responds with 401 if authenticating via token with TA key' do
        get '/api/upvs/user/info.saml', headers: { 'Authorization' => 'Bearer ' + api_token_with_ta_key }

        expect(response.status).to eq(401)
        expect(response.body).to eq({ message: 'Bad credentials' }.to_json)
      end

      pending 'responds with 500 if anything else fails'
    end
  end

  context 'without UPVS SSO support', sso: false do
    describe 'GET /api/upvs/user/info' do
      it 'responds with 404' do
        get '/api/upvs/user/info'

        expect(response.status).to eq(404)
      end
    end

    describe 'GET /api/upvs/user/info.saml' do
      it 'responds with 404' do
        get '/api/upvs/user/info.saml'

        expect(response.status).to eq(404)
      end
    end
  end
end
