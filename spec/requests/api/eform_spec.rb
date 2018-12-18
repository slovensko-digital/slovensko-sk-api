require 'rails_helper'

RSpec.describe 'eForm API' do
  describe 'POST /api/eform/validate' do
    valid_form_xml = <<~HEREDOC
      <GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.7" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <subject>some subject</subject>
        <text>some text</text>
      </GeneralAgenda>
    HEREDOC
    default_params = { identifier: 'App.GeneralAgenda', version: '1.7', data: valid_form_xml, token: 'TEST_TOKEN' }

    let(:response_object) { JSON.parse(response.body) }

    before(:each) do
      create(:form_template_related_document, :general_agenda_xsd_schema)
      allow(ApiEnvironment.token_authenticator).to receive(:verify_token).with('TEST_TOKEN')
    end

    def post_request(params)
      post '/api/eform/validate', params: params
    end

    describe 'auth token' do
      it 'is required' do
        expect(ApiEnvironment.token_authenticator).to receive(:verify_token).with('invalid').and_call_original
        post_request default_params.merge({ token: 'invalid' })
        expect(response.status).to eq(401)
      end

      pending 'does not need obo token'
    end

    context 'when form data is valid' do
      it 'returns validation result' do
        post_request default_params
        expect(response_object['valid']).to eq(true)
        expect(response_object['errors']).to be_blank
      end
    end

    context 'when form data is invalid' do
      invalid_form_xml = <<~HEREDOC
        <InvalidForm>
        </InvalidForm>
      HEREDOC

      it 'lists validation errors' do
        post_request default_params.merge({ data: invalid_form_xml })
        expect(response_object['valid']).to eq(false)
        expect(response_object['errors']).to be_present
      end
    end

    context 'when parameters are missing' do
      pending 'returns 400 with a message'
    end

    context 'when form or xsd schema is not found' do
      pending 'returns 400 with a message'
    end

    context 'when submitted form has parsing issues' do
      unparseable = 'Not an XML.'

      it 'the form is deemed invalid' do
        post_request default_params.merge({ data: unparseable })
        expect(response_object['valid']).to eq(false)
        expect(response_object['errors']).to include('Malformed XML')
      end
    end
  end
end
