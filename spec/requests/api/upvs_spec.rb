require 'rails_helper'

RSpec.describe 'UPVS API' do
  let!(:token) { api_token_with_obo_token_from_response(file_fixture('oam/sso_response_success.xml').read) }

  let(:assertion) { file_fixture('oam/sso_response_success_assertion.xml').read.strip }

  before(:example) { travel_to '2018-11-28T20:26:16Z' }

  after(:example) { travel_back }

  describe 'GET /api/upvs/user/info.saml' do
    it 'returns SAML assertion' do
      get '/api/upvs/user/info.saml', headers: { 'Authorization' => 'Bearer ' + token }

      expect(response.status).to eq(200)
      expect(response.body).to eq(assertion)

      expect(response.content_type).to eq('application/saml')
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
      get '/api/upvs/user/info.saml', headers: { 'Authorization' => 'Bearer ' + token }

      expect(response.status).to eq(200)
    end

    it 'responds with 400 if request does not contain any authentication' do
      get '/api/upvs/user/info.saml'

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No credentials' }.to_json)
    end

    it 'responds with 401 if authentication does not pass' do
      travel_to Time.now + 20.minutes

      get '/api/upvs/user/info.saml', headers: { 'Authorization' => 'Bearer ' + token }

      travel_back

      expect(response.status).to eq(401)
      expect(response.body).to eq({ message: 'Bad credentials' }.to_json)
    end

    pending 'responds with 500 if anything else fails'
  end
end
