require 'rails_helper'

RSpec.describe 'eForm API' do
  allow_api_token_with_obo_token!
  skip_upvs_subject_verification!

  let(:token) { api_token_with_subject }
  let(:upvs) { upvs_proxy_double }

  describe 'GET /api/eform/status' do
    let(:params) do
      {
        identifier: 'App.GeneralAgenda',
        version: '1.9'
      }
    end

    let(:ez_service) { sk.gov.schemas.servicebus.service._1.ServiceClassEnum::EFORM_GETFORMTEMPLATESTATUS_SOAP_V_1_0 }
    let(:ez_request_class) { sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.GetFormTemplateStatusReq }
    let(:ez_response_class) { sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.GetFormTemplateStatusRes }

    def set_upvs_expectations
      # TODO test against request template here not just class -> use custom matcher which does UpvsObjects.to_structure(actual) == UpvsObjects.to_structure(xxx_request('xxx/xxx_request.xml'))
      expect(upvs.ez).to receive(:call_service).with(ez_service, kind_of(ez_request_class)).and_return(usr_service_result('ez/eform/get_form_template_status_response.xml'))
    end

    it 'returns form status' do
      set_upvs_expectations

      get '/api/eform/status', headers: headers, params: params

      expect(response.status).to eq(200)
      expect(response.object).to eq(status: 'Publikovaný')
    end

    include_examples 'API request media types', get: '/api/eform/status', accept: 'application/json'
    include_examples 'API request authentication', get: '/api/eform/status', allow_sub: true

    it 'responds with 400 if request does not contain identifier' do
      get '/api/eform/status', headers: headers, params: params.except(:identifier)

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No identifier')
    end

    it 'responds with 400 if request does not contain version' do
      get '/api/eform/status', headers: headers, params: params.except(:version)

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No version')
    end

    it 'responds with 404 if template can not be found' do
      expect(upvs.ez).to receive(:call_service).and_raise(soap_fault_exception('06000798'))

      get '/api/eform/status', headers: headers, params: params

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Template not found')
    end

    include_examples 'USR request timeout', get: '/api/eform/status'

    pending 'responds with 429 if request rate limit exceeds'

    include_examples 'USR request failure', get: '/api/eform/status'
    include_examples 'UPVS proxy initialization', get: '/api/eform/status', allow_sub: true
  end

  describe 'POST /api/eform/validate' do
    let(:params) do
      {
        identifier: 'App.GeneralAgenda',
        version: '1.9',
        form: file_fixture('sktalk/forms/general_agenda.xml').read
      }
    end

    before(:example) { create(:form_template_related_document, :general_agenda_xsd_schema) }

    it 'validates valid form' do
      post '/api/eform/validate', headers: headers, params: params, as: :json

      expect(response.status).to eq(200)
      expect(response.object).to eq(valid: true)
    end

    pending 'validates valid form with largest possible payload'

    it 'validates invalid form' do
      post '/api/eform/validate', headers: headers, params: params.merge(form: '<GeneralAgenda/>'), as: :json

      expect(response.status).to eq(200)
      expect(response.object).to eq(valid: false, errors: ["-1:-1: ERROR: cvc-elt.1.a: Cannot find the declaration of element 'GeneralAgenda'."])
    end

    pending 'validates invalid form with largest possible payload'

    include_examples 'API request media types', post: '/api/eform/validate', accept: 'application/json'
    include_examples 'API request authentication', post: '/api/eform/validate', allow_sub: true

    it 'responds with 400 if request does not contain identifier' do
      post '/api/eform/validate', headers: headers, params: params.except(:identifier), as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No identifier')
    end

    it 'responds with 400 if request does not contain version' do
      post '/api/eform/validate', headers: headers, params: params.except(:version), as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No version')
    end

    it 'responds with 400 if request does not contain form' do
      post '/api/eform/validate', headers: headers, params: params.except(:form), as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No form')
    end

    it 'responds with 400 if request contains invalid form' do
      post '/api/eform/validate', headers: headers, params: params.merge(form: 'INVALID'), as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'Invalid form')
    end

    it 'responds with 404 if template can not be found' do
      post '/api/eform/validate', headers: headers, params: params.merge(identifier: 'App.UnknownAgenda', version: '1.0'), as: :json

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Template not found')
    end

    it 'responds with 404 if schema can not be found' do
      create(:form_template, identifier: 'App.UnknownAgenda', version_major: 1, version_minor: 0)

      post '/api/eform/validate', headers: headers, params: params.merge(identifier: 'App.UnknownAgenda', version: '1.0'), as: :json

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Schema not found')
    end

    pending 'responds with 413 if payload is too large'

    pending 'responds with 429 if request rate limit exceeds'
  end

  describe 'GET /api/eform/form_template_related_document' do
    let(:params) do
      {
        identifier: 'App.GeneralAgenda',
        version: '1.9',
        type: 'CLS_F_XSD_EDOC'
      }.as_json
    end

    before(:example) { create(:form_template_related_document, :general_agenda_xsd_schema) }

    it 'returns form related document' do

      get '/api/eform/form_template_related_document', headers: headers, params: params

      expect(response.status).to eq(200)
      expect(response.object).to eq(document: Base64.encode64(FormTemplateRelatedDocument.last.data))
    end

    include_examples 'API request media types', get: '/api/eform/form_template_related_document', accept: 'application/json'
    include_examples 'API request authentication', get: '/api/eform/form_template_related_document', allow_sub: true

    it 'responds with 400 if request does not contain identifier' do
      get '/api/eform/form_template_related_document', headers: headers, params: params.except('identifier')

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No identifier')
    end

    it 'responds with 400 if request does not contain version' do
      get '/api/eform/form_template_related_document', headers: headers, params: params.except('version')

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No version')
    end

    it 'responds with 400 if request does not contain type' do
      get '/api/eform/form_template_related_document', headers: headers, params: params.except('type')

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No type')
    end

    it 'responds with 404 if template can not be found' do
      get '/api/eform/form_template_related_document', headers: headers, params: params.merge(identifier: 'App.UnknownAgenda', version: '1.0')

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Template not found')
    end

    it 'responds with 404 if template related document can not be found' do
      create(:form_template, identifier: 'App.UnknownAgenda', version_major: 1, version_minor: 0)

      get '/api/eform/form_template_related_document', headers: headers, params: params.merge(identifier: 'App.UnknownAgenda', version: '1.0')

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Template related document not found')
    end

    pending 'responds with 429 if request rate limit exceeds'
  end
end
