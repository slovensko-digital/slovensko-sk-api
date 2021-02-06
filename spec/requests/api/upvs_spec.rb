require 'rails_helper'

RSpec.describe 'UPVS API' do
  context 'with UPVS SSO support', if: sso_support? do
    allow_api_token_with_obo_token!
    skip_upvs_subject_verification!

    let(:token) { api_token_with_obo_token(scopes: ['upvs/assertion', 'upvs/identity']) }
    let(:upvs) { upvs_proxy_double }

    describe 'GET /api/upvs/assertion' do
      let(:headers) do
        {
          'Authorization' => 'Bearer ' + token,
          'Accept' => 'application/samlassertion+xml'
        }
      end

      let(:assertion) { file_fixture('oam/sso_response_success_assertion.xml').read.strip }

      it 'returns SAML assertion' do
        get '/api/upvs/assertion', headers: headers

        expect(response.status).to eq(200)
        expect(response.body).to eq(assertion)
      end

      include_examples 'API request media types', get: '/api/upvs/assertion', accept: 'application/samlassertion+xml'
      include_examples 'API request authentication', get: '/api/upvs/assertion', allow_obo_token: true
    end

    describe 'GET /api/upvs/identity' do
      def set_upvs_expectations
        # TODO test against request template here not just class -> use custom matcher which does UpvsObjects.to_structure(actual) == UpvsObjects.to_structure(xxx_request('xxx/xxx_request.xml'))
        expect(upvs.iam).to receive(:get_identity).with(kind_of(sk.gov.schemas.identity.service._1.GetIdentityRequest)).and_return(iam_response('iam/get_identity_response.xml'))
      end

      it 'returns identity' do
        set_upvs_expectations

        get '/api/upvs/identity', headers: headers

        expect(response.status).to eq(200)
        expect(response.object).to eq(JSON.parse(file_fixture('api/iam/identity.json').read, symbolize_names: true))
      end

      include_examples 'API request media types', get: '/api/upvs/identity', accept: 'application/json'
      include_examples 'API request authentication', get: '/api/upvs/identity', allow_obo_token: true

      it 'responds with 400 if IAM raises IAM fault' do
        expect(upvs.iam).to receive(:get_identity).with(kind_of(sk.gov.schemas.identity.service._1.GetIdentityRequest)).and_raise(iam_get_identity_fault('iam/get_identity/undefined_fault.xml'))

        get '/api/upvs/identity', headers: headers

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Invalid identity identifier', fault: { code: '00000000', reason: 'Nedefinovaná chyba!' })
      end

      it 'responds with 408 if IAM raises timeout error' do
        expect(upvs.iam).to receive(:get_identity).and_raise(soap_timeout_exception)

        get '/api/upvs/identity', headers: headers

        expect(response.status).to eq(408)
        expect(response.object).to eq(message: 'Operation timeout exceeded')
      end

      pending 'responds with 429 if request rate limit exceeds'

      it 'responds with 500 if IAM raises internal error' do
        expect(upvs.iam).to receive(:get_identity).and_raise

        get '/api/upvs/identity', headers: headers

        expect(response.status).to eq(500)
        expect(response.object).to eq(message: 'Unknown error')
      end

      it 'responds with 503 if IAM raises SOAP fault' do
        expect(upvs.iam).to receive(:get_identity).and_raise(soap_fault_exception)

        get '/api/upvs/identity', headers: headers

        expect(response.status).to eq(503)
        expect(response.object).to eq(message: 'Unknown failure')
      end

      include_examples 'UPVS proxy initialization', get: '/api/upvs/identity', allow_obo_token: true
    end
  end

  context 'without UPVS SSO support', unless: sso_support? do
    describe 'GET /api/upvs/assertion' do
      it 'responds with 404' do
        get '/api/upvs/assertion'

        expect(response.status).to eq(404)
      end
    end

    describe 'GET /api/upvs/identity' do
      it 'responds with 404' do
        get '/api/upvs/identity'

        expect(response.status).to eq(404)
      end
    end
  end
end
