require 'rails_helper'

RSpec.describe 'eForm API' do
  let(:upvs_proxy) { instance_double(UpvsProxy) }
  let(:eform_service) { EformService.new(upvs_proxy) }

  let!(:token) { api_token_with_ta_key }

  before(:example) do
    allow(UpvsEnvironment).to receive(:eform_service).and_return(eform_service)
  end

  describe 'GET /api/eform/status' do
    before(:example) do
      allow(eform_service).to receive(:fetch_form_template_status).with('App.GeneralAgenda', '1.9').and_return('Publikovaný')
    end

    it 'returns form status' do
      get '/api/eform/status', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.9' }

      expect(response.status).to eq(200)
      expect(response.body).to eq({ status: 'Publikovaný' }.to_json)

      expect(response.content_type).to eq('application/json')
      expect(response.charset).to eq('utf-8')
    end

    it 'supports authentication via headers' do
      get '/api/eform/status', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.9' }

      expect(response.status).to eq(200)
    end

    it 'supports authentication via parameters' do
      get '/api/eform/status', params: { token: token, identifier: 'App.GeneralAgenda', version: '1.9' }

      expect(response.status).to eq(200)
    end

    it 'prefers authentication via headers over parameters' do
      get '/api/eform/status', headers: { 'Authorization' => 'Bearer ' + token }, params: { token: 'INVALID', identifier: 'App.GeneralAgenda', version: '1.9' }

      expect(response.status).to eq(200)
    end

    it 'allows authentication via tokens with TA key' do
      get '/api/eform/status', headers: { 'Authorization' => 'Bearer ' + api_token_with_ta_key }, params: { identifier: 'App.GeneralAgenda', version: '1.9' }

      expect(response.status).to eq(200)
    end

    it 'responds with 400 if request does not contain any authentication' do
      get '/api/eform/status', params: { identifier: 'App.GeneralAgenda', version: '1.9' }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No credentials' }.to_json)
    end

    it 'responds with 400 if request does not contain form identifier' do
      get '/api/eform/status', headers: { 'Authorization' => 'Bearer ' + token }, params: { version: '1.9' }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No form identifier' }.to_json)
    end

    it 'responds with 400 if request does not contain form version' do
      get '/api/eform/status', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda' }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No form version' }.to_json)
    end

    it 'responds with 401 if authenticating via expired token' do
      travel_to Time.now + 20.minutes

      get '/api/eform/status', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.9' }

      travel_back

      expect(response.status).to eq(401)
      expect(response.body).to eq({ message: 'Bad credentials' }.to_json)
    end

    it 'responds with 401 if authenticating via token with OBO token' do
      get '/api/eform/status', headers: { 'Authorization' => 'Bearer ' + api_token_with_obo_token_from_response(file_fixture('oam/sso_response_success.xml').read) }, params: { identifier: 'App.GeneralAgenda', version: '1.9' }

      expect(response.status).to eq(401)
      expect(response.body).to eq({ message: 'Bad credentials' }.to_json)
    end

    it 'responds with 404 if request contains form which can not be found' do
      expect(eform_service).to receive(:fetch_form_template_status).with('App.UnknownAgenda', '1.0').and_raise(execution_exception(soap_fault_exception('06000798')))

      get '/api/eform/status', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.UnknownAgenda', version: '1.0' }

      expect(response.status).to eq(404)
      expect(response.body).to eq({ message: 'Form App.UnknownAgenda version 1.0 not found' }.to_json)
    end

    pending 'responds with 429 if request rate limit exceeds'

    pending 'responds with 500 if external service fails'

    pending 'responds with 500 if anything else fails'
  end

  describe 'POST /api/eform/validate' do
    let(:general_agenda) do
      <<~FORM
        <GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <subject>Všeobecný predment</subject>
          <text>Všeobecný text</text>
        </GeneralAgenda>
      FORM
    end

    before(:example) { create(:form_template_related_document, :general_agenda_xsd_schema) }

    it 'validates valid form data' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.9', data: general_agenda }

      expect(response.status).to eq(200)
      expect(response.body).to eq({ valid: true }.to_json)

      expect(response.content_type).to eq('application/json')
      expect(response.charset).to eq('utf-8')
    end

    pending 'validates valid form data in request with largest possible payload'

    it 'validates invalid form data' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.9', data: '<GeneralAgenda/>' }

      expect(response.status).to eq(200)
      expect(response.body).to eq({ valid: false, errors: ["-1:-1: ERROR: cvc-elt.1.a: Cannot find the declaration of element 'GeneralAgenda'."]}.to_json)

      expect(response.content_type).to eq('application/json')
      expect(response.charset).to eq('utf-8')
    end

    it 'supports authentication via headers' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.9', data: general_agenda }

      expect(response.status).to eq(200)
    end

    it 'supports authentication via parameters' do
      post '/api/eform/validate', params: { token: token, identifier: 'App.GeneralAgenda', version: '1.9', data: general_agenda }

      expect(response.status).to eq(200)
    end

    it 'prefers authentication via headers over parameters' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { token: 'INVALID', identifier: 'App.GeneralAgenda', version: '1.9', data: general_agenda }

      expect(response.status).to eq(200)
    end

    it 'allows authentication via tokens with TA key' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + api_token_with_ta_key }, params: { identifier: 'App.GeneralAgenda', version: '1.9', data: general_agenda }

      expect(response.status).to eq(200)
    end

    it 'responds with 400 if request does not contain any authentication' do
      post '/api/eform/validate', params: { identifier: 'App.GeneralAgenda', version: '1.9', data: general_agenda }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No credentials' }.to_json)
    end

    it 'responds with 400 if request does not contain form identifier' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { version: '1.9', data: general_agenda }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No form identifier' }.to_json)
    end

    it 'responds with 400 if request does not contain form version' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', data: general_agenda }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No form version' }.to_json)
    end

    it 'responds with 400 if request does not contain form data to validate' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.9' }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No form data' }.to_json)
    end

    it 'responds with 400 if request contains malformed form data to validate' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.9', data: 'INVALID' }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'Malformed form data' }.to_json)
    end

    it 'responds with 401 if authenticating via expired token' do
      travel_to Time.now + 20.minutes

      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.9', data: general_agenda }

      travel_back

      expect(response.status).to eq(401)
      expect(response.body).to eq({ message: 'Bad credentials' }.to_json)
    end

    it 'responds with 401 if authenticating via token with OBO token' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + api_token_with_obo_token_from_response(file_fixture('oam/sso_response_success.xml').read) }, params: { identifier: 'App.GeneralAgenda', version: '1.9', data: general_agenda }

      expect(response.status).to eq(401)
      expect(response.body).to eq({ message: 'Bad credentials' }.to_json)
    end

    it 'responds with 404 if request contains form which can not be found' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.UnknownAgenda', version: '1.0', data: general_agenda }

      expect(response.status).to eq(404)
      expect(response.body).to eq({ message: 'Form App.UnknownAgenda version 1.0 not found' }.to_json)
    end

    it 'responds with 404 if request contains form which has no schema' do
      create(:form_template, identifier: 'DCOM_eDemokracia_ZiadostOVydanieVolicskehoPreukazuFO_sk', version_major: 1, version_minor: 0)

      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'DCOM_eDemokracia_ZiadostOVydanieVolicskehoPreukazuFO_sk', version: '1.0', data: general_agenda }

      expect(response.status).to eq(404)
      expect(response.body).to eq({ message: 'Validation schema of form DCOM_eDemokracia_ZiadostOVydanieVolicskehoPreukazuFO_sk version 1.0 not found' }.to_json)
    end

    pending 'responds with 413 if payload is too large'

    pending 'responds with 429 if request rate limit exceeds'

    pending 'responds with 500 if anything else fails'
  end
end
