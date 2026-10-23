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

  describe 'GET /api/eform/form_template_metadata' do
    let(:params) do
      {
        identifier: 'App.GeneralAgenda',
        version: '1.9'
      }.as_json
    end

    let(:ez_service) { sk.gov.schemas.servicebus.service._1.ServiceClassEnum::EFORM_GETFORMTEMPLATEMETADATA_SOAP_V_1_0 }
    let(:ez_request_class) { sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.GetFormTemplateMetaDataReq }
    let(:ez_response_class) { sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.GetFormTemplateMetaDataRes }

    def set_upvs_expectations
      # TODO test against request template here not just class -> use custom matcher which does UpvsObjects.to_structure(actual) == UpvsObjects.to_structure(xxx_request('xxx/xxx_request.xml'))
      expect(upvs.ez).to receive(:call_service).with(ez_service, kind_of(ez_request_class)).and_return(usr_service_result('ez/eform/get_form_template_metadata_response.xml'))
    end

    it 'returns form metadata' do
      set_upvs_expectations

      get '/api/eform/form_template_metadata', headers: headers, params: params

      expect(response.status).to eq(200)
      expect(response.object).to eq(identifier: 'App.GeneralAgenda', title: 'Všeobecná agenda', type: 'eForm', gestor: 'Skutocny1145 Emil', publisher: 'ico://sk/42156424_90000', section: nil, agenda: nil, source: nil, version_major: 1, version_minor: 9, valid_from: '2015-04-08T00:00:00', valid_to: '0001-01-01T00:00:00', keywords: nil, access_group: nil)
    end

    include_examples 'API request media types', get: '/api/eform/form_template_metadata', accept: 'application/json'
    include_examples 'API request authentication', get: '/api/eform/form_template_metadata', allow_sub: true

    it 'responds with 400 if request does not contain identifier' do
      get '/api/eform/form_template_metadata', headers: headers, params: params.except('identifier')

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No identifier')
    end

    it 'responds with 400 if request does not contain version' do
      get '/api/eform/form_template_metadata', headers: headers, params: params.except('version')

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No version')
    end

    it 'responds with 404 if template can not be found' do
      expect(upvs.ez).to receive(:call_service).with(ez_service, kind_of(ez_request_class)).and_raise(soap_fault_exception('06000798'))

      get '/api/eform/form_template_metadata', headers: headers, params: params.merge(identifier: 'App.UnknownAgenda', version: '1.0')

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Template not found')
    end

    pending 'responds with 429 if request rate limit exceeds'
  end

  describe 'GET /api/eform/form_package' do
    let(:params) do
      {
        identifier: 'App.GeneralAgenda',
        version: '1.9'
      }.as_json
    end

    let(:ez_service) { sk.gov.schemas.servicebus.service._1.ServiceClassEnum::EFORM_GETEFORMPACKAGE_SOAP_V_1_0 }
    let(:ez_request_class) { sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.GetEFormPackageReq }
    let(:ez_response_class) { sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.GetEFormPackageRes }

    def set_upvs_expectations
      # TODO test against request template here not just class -> use custom matcher which does UpvsObjects.to_structure(actual) == UpvsObjects.to_structure(xxx_request('xxx/xxx_request.xml'))
      expect(upvs.ez).to receive(:call_service).with(ez_service, kind_of(ez_request_class)).and_return(usr_service_result('ez/eform/get_form_package_response.xml'))
    end

    it 'returns form package' do
      set_upvs_expectations

      get '/api/eform/form_package', headers: headers, params: params

      expect(response.status).to eq(200)
      expect(response.object).to eq(data: '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')
    end

    include_examples 'API request media types', get: '/api/eform/form_package', accept: 'application/json'
    include_examples 'API request authentication', get: '/api/eform/form_package', allow_sub: true

    it 'responds with 400 if request does not contain identifier' do
      get '/api/eform/form_package', headers: headers, params: params.except('identifier')

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No identifier')
    end

    it 'responds with 400 if request does not contain version' do
      get '/api/eform/form_package', headers: headers, params: params.except('version')

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No version')
    end

    it 'responds with 404 if template can not be found' do
      expect(upvs.ez).to receive(:call_service).with(ez_service, kind_of(ez_request_class)).and_raise(soap_fault_exception('Nie je možné vygenerovať vzor formulára.'))

      get '/api/eform/form_package', headers: headers, params: params.merge(identifier: 'App.UnknownAgenda', version: '1.0')

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Template not found')
    end

    pending 'responds with 429 if request rate limit exceeds'
  end
end
