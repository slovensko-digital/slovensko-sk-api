require 'rails_helper'

RSpec.describe 'eForm API' do
  let!(:token) { api_token_without_obo_token }

  describe 'POST /api/eform/validate' do
    let(:general_agenda) do
      <<~FORM
        <GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.7" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <subject>some subject</subject>
          <text>some text</text>
        </GeneralAgenda>
      FORM
    end

    before(:example) { create(:form_template_related_document, :general_agenda_xsd_schema) }

    it 'validates valid form data' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.7', data: general_agenda }

      expect(response.status).to eq(200)
      expect(response.body).to eq({ valid: true }.to_json)
    end

    pending 'validates valid form data in request with largest possible payload'

    it 'validates invalid form data' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.7', data: '<GeneralAgenda/>' }

      expect(response.status).to eq(200)
      expect(response.body).to eq({ valid: false, errors: ["-1:-1: ERROR: cvc-elt.1.a: Cannot find the declaration of element 'GeneralAgenda'."]}.to_json)
    end

    it 'supports authentication via headers' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.7', data: general_agenda }

      expect(response.status).to eq(200)
    end

    it 'supports authentication via parameters' do
      post '/api/eform/validate', params: { token: token, identifier: 'App.GeneralAgenda', version: '1.7', data: general_agenda }

      expect(response.status).to eq(200)
    end

    it 'prefers authentication via headers over parameters' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { token: 'INVALID', identifier: 'App.GeneralAgenda', version: '1.7', data: general_agenda }

      expect(response.status).to eq(200)
    end

    it 'responds with 400 if request does not contain any authentication' do
      post '/api/eform/validate', params: { identifier: 'App.GeneralAgenda', version: '1.7', data: general_agenda }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No credentials' }.to_json)
    end

    it 'responds with 400 if request does not contain form identifier' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { version: '1.7', data: general_agenda }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No form identifier' }.to_json)
    end

    it 'responds with 400 if request does not contain form version' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', data: general_agenda }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No form version' }.to_json)
    end

    it 'responds with 400 if request does not contain form data to validate' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.7' }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No form data' }.to_json)
    end

    it 'responds with 400 if request contains malformed form data to validate' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.7', data: 'INVALID' }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'Malformed form data' }.to_json)
    end

    it 'responds with 401 if authentication does not pass' do
      travel_to Time.now + 20.minutes

      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.7', data: general_agenda }

      travel_back

      expect(response.status).to eq(401)
      expect(response.body).to eq({ message: 'Bad credentials' }.to_json)
    end

    it 'responds with 404 if request contains form which can not be found' do
      post '/api/eform/validate', headers: { 'Authorization' => 'Bearer ' + token }, params: { identifier: 'App.GeneralAgenda', version: '1.9', data: general_agenda }

      expect(response.status).to eq(404)
      expect(response.body).to eq({ message: 'Form App.GeneralAgenda version 1.9 not found' }.to_json)
    end

    pending 'responds with 408 if external service times out'

    pending 'responds with 413 if payload is too large'

    pending 'responds with 429 if request rate limit exceeds'

    pending 'responds with 500 if external service fails'

    pending 'responds with 500 if anything else fails'
  end
end
