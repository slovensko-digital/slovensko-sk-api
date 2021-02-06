require 'rails_helper'

RSpec.describe 'IAM API' do
  allow_api_token_with_obo_token!
  skip_upvs_subject_verification!

  let(:token) { api_token_with_subject }
  let(:upvs) { upvs_proxy_double }

  describe 'GET /api/iam/identities/{id}' do
    def set_upvs_expectations
      # TODO test against request template here not just class -> use custom matcher which does UpvsObjects.to_structure(actual) == UpvsObjects.to_structure(xxx_request('xxx/xxx_request.xml'))
      expect(upvs.iam).to receive(:get_identity).with(kind_of(sk.gov.schemas.identity.service._1.GetIdentityRequest)).and_return(iam_response('iam/get_identity_response.xml'))
    end

    it 'returns identity' do
      set_upvs_expectations

      get '/api/iam/identities/6d9dc77b-70ed-432f-abaa-5de8753c967c', headers: headers

      expect(response.status).to eq(200)
      expect(response.object).to eq(JSON.parse(file_fixture('api/iam/identity.json').read, symbolize_names: true))
    end

    include_examples 'API request media types', get: '/api/iam/identities/6d9dc77b-70ed-432f-abaa-5de8753c967c', accept: 'application/json'
    include_examples 'API request authentication', get: '/api/iam/identities/6d9dc77b-70ed-432f-abaa-5de8753c967c', allow_sub: true

    it 'responds with 400 if request contains invalid identity identifier' do
      expect(upvs.iam).to receive(:get_identity).with(kind_of(sk.gov.schemas.identity.service._1.GetIdentityRequest)).and_raise(iam_get_identity_fault('iam/get_identity/invalid_identifier_fault.xml'))

      get '/api/iam/identities/0', headers: headers

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'Invalid identity identifier', fault: { code: '00074421', reason: 'Nastala chyba: IDENTITY_ID_FAULT' })
    end

    it 'responds with 400 if IAM raises IAM fault' do
      expect(upvs.iam).to receive(:get_identity).with(kind_of(sk.gov.schemas.identity.service._1.GetIdentityRequest)).and_raise(iam_get_identity_fault('iam/get_identity/undefined_fault.xml'))

      get '/api/iam/identities/6d9dc77b-70ed-432f-abaa-5de8753c967c', headers: headers

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'Invalid identity identifier', fault: { code: '00000000', reason: 'Nedefinovaná chyba!' })
    end

    it 'responds with 408 if IAM raises timeout error' do
      expect(upvs.iam).to receive(:get_identity).and_raise(soap_timeout_exception)

      get '/api/iam/identities/6d9dc77b-70ed-432f-abaa-5de8753c967c', headers: headers

      expect(response.status).to eq(408)
      expect(response.object).to eq(message: 'Operation timeout exceeded')
    end

    pending 'responds with 429 if request rate limit exceeds'

    it 'responds with 500 if IAM raises internal error' do
      expect(upvs.iam).to receive(:get_identity).and_raise

      get '/api/iam/identities/6d9dc77b-70ed-432f-abaa-5de8753c967c', headers: headers

      expect(response.status).to eq(500)
      expect(response.object).to eq(message: 'Unknown error')
    end

    it 'responds with 503 if IAM raises SOAP fault' do
      expect(upvs.iam).to receive(:get_identity).and_raise(soap_fault_exception)

      get '/api/iam/identities/6d9dc77b-70ed-432f-abaa-5de8753c967c', headers: headers

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'Unknown failure')
    end

    include_examples 'UPVS proxy initialization', get: '/api/iam/identities/6d9dc77b-70ed-432f-abaa-5de8753c967c', allow_sub: true
  end

  describe 'POST /api/iam/identities/search' do
    let(:params) do
      {
        ids: ['...']
      }
    end

    def set_upvs_expectations
      # TODO test against request template here not just class -> use custom matcher which does UpvsObjects.to_structure(actual) == UpvsObjects.to_structure(xxx_request('xxx/xxx_request.xml'))
      expect(upvs.iam).to receive(:get_edesk_info2).with(kind_of(sk.gov.schemas.identity.service._1.GetEdeskInfo2Request)).and_return(iam_response('iam/get_edesk_info_response.xml'))
    end

    it 'finds identities' do
      set_upvs_expectations

      post '/api/iam/identities/search', headers: headers, params: params, as: :json

      expect(response.status).to eq(200)
      expect(response.object).to eq(JSON.parse(file_fixture('api/iam/identities/search.json').read, symbolize_names: true))
    end

    context 'pagination' do
      it 'finds identities at given page' do
        set_upvs_expectations # TODO test against page in request here

        post '/api/iam/identities/search', headers: headers, params: params.merge(page: 2), as: :json

        expect(response.status).to eq(200)
      end

      it 'finds identities at given page and with given per page' do
        set_upvs_expectations # TODO test against page + per_page in request here

        post '/api/iam/identities/search', headers: headers, params: params.merge(page: 2, per_page: 20), as: :json

        expect(response.status).to eq(200)
      end

      it 'finds identities with given per page' do
        set_upvs_expectations # TODO test against per_page in request here

        post '/api/iam/identities/search', headers: headers, params: params.merge(per_page: 20), as: :json

        expect(response.status).to eq(200)
      end

      it 'responds with 400 if given page number is invalid' do
        post '/api/iam/identities/search', headers: headers, params: params.merge(page: '1x'), as: :json

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Invalid page number')
      end

      it 'responds with 400 if given page number is zero' do
        post '/api/iam/identities/search', headers: headers, params: params.merge(page: 0), as: :json

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Invalid page number')
      end

      pending 'responds with 400 if given page number is too large'

      it 'responds with 400 if given per page number is invalid' do
        post '/api/iam/identities/search', headers: headers, params: params.merge(per_page: '1x'), as: :json

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Invalid per page number')
      end

      it 'responds with 400 if given per page number is too small' do
        post '/api/iam/identities/search', headers: headers, params: params.merge(per_page: 9), as: :json

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Per page number out of range')
      end

      it 'responds with 400 if given per page number is too large' do
        post '/api/iam/identities/search', headers: headers, params: params.merge(per_page: 101), as: :json

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Per page number out of range')
      end
    end

    include_examples 'API request media types', post: '/api/iam/identities/search', accept: 'application/json'
    include_examples 'API request authentication', post: '/api/iam/identities/search', allow_sub: true

    it 'responds with 400 if request does not contain query' do
      post '/api/iam/identities/search', headers: headers, params: {}, as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No query')
    end

    it 'responds with 400 if request contains invalid query' do
      expect(upvs.iam).to receive(:get_edesk_info2).with(kind_of(sk.gov.schemas.identity.service._1.GetEdeskInfo2Request)).and_raise(iam_get_edesk_info_fault('iam/get_edesk_info/invalid_query_fault.xml'))

      post '/api/iam/identities/search', headers: headers, params: params, as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'Invalid query', fault: { code: '01000999', reason: 'Chybný vstup, kombinácia PhysicalPerson a CorporateBody' })
    end

    it 'responds with 400 if IAM raises IAM fault' do
      expect(upvs.iam).to receive(:get_edesk_info2).with(kind_of(sk.gov.schemas.identity.service._1.GetEdeskInfo2Request)).and_raise(iam_get_edesk_info_fault('iam/get_edesk_info/undefined_fault.xml'))

      post '/api/iam/identities/search', headers: headers, params: params, as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'Invalid query', fault: { code: '00000000', reason: 'Nedefinovaná chyba!' })
    end

    it 'responds with 408 if IAM raises timeout error' do
      expect(upvs.iam).to receive(:get_edesk_info2).and_raise(soap_timeout_exception)

      post '/api/iam/identities/search', headers: headers, params: params, as: :json

      expect(response.status).to eq(408)
      expect(response.object).to eq(message: 'Operation timeout exceeded')
    end

    pending 'responds with 429 if request rate limit exceeds'

    it 'responds with 500 if IAM raises internal error' do
      expect(upvs.iam).to receive(:get_edesk_info2).and_raise

      post '/api/iam/identities/search', headers: headers, params: params, as: :json

      expect(response.status).to eq(500)
      expect(response.object).to eq(message: 'Unknown error')
    end

    it 'responds with 503 if IAM raises SOAP fault' do
      expect(upvs.iam).to receive(:get_edesk_info2).and_raise(soap_fault_exception)

      post '/api/iam/identities/search', headers: headers, params: params, as: :json

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'Unknown failure')
    end

    include_examples 'UPVS proxy initialization', post: '/api/iam/identities/search', allow_sub: true
  end
end
