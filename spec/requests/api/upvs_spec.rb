require 'rails_helper'

RSpec.describe 'UPVS API' do
  context 'with UPVS SSO support', if: sso_support? do
    allow_api_token_with_obo_token!
    skip_upvs_subject_verification!

    let(:token) { api_token_with_obo_token }

    describe 'GET /api/upvs/sso/assertion' do
      let(:headers) do
        {
          'Authorization' => 'Bearer ' + token,
          'Accept' => 'application/samlassertion+xml'
        }
      end

      let(:assertion) { file_fixture('oam/sso_response_success_assertion.xml').read.strip }

      it 'returns SAML assertion' do
        get '/api/upvs/sso/assertion', headers: headers

        expect(response.status).to eq(200)
        expect(response.body).to eq(assertion)
      end

      include_examples 'API request media types', get: '/api/upvs/sso/assertion', accept: 'application/samlassertion+xml'
      include_examples 'API request authentication', get: '/api/upvs/sso/assertion', allow_obo_token: true
    end
  end

  context 'without UPVS SSO support', unless: sso_support? do
    describe 'GET /api/upvs/sso/assertion' do
      it 'responds with 404' do
        get '/api/upvs/sso/assertion'

        expect(response.status).to eq(404)
      end
    end
  end
end
