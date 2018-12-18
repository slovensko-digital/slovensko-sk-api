require 'rails_helper'

RSpec.describe 'eForm API' do
  describe 'POST /api/eform/validate' do
    valid_form_xml = <<~HEREDOC
      <GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.7" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <subject>some subject</subject>
        <text>some text</text>
      </GeneralAgenda>
    HEREDOC

    let(:token) do
      response = OneLogin::RubySaml::Response.new(file_fixture('oam/response_success.xml').read)
      header = { cty: 'JWT' }
      payload = { exp: response.not_on_or_after.to_i, jti: SecureRandom.uuid }

      JWT.encode(payload, api_token_key_pair, 'RS256', header)
    end

    let(:default_params) {{ identifier: 'App.GeneralAgenda', version: '1.7', data: valid_form_xml, token: token }}
    let(:response_object) { JSON.parse(response.body) }

    before(:example) do
      create(:form_template_related_document, :general_agenda_xsd_schema)
    end

    before(:example) { travel_to '2018-11-28T20:26:16Z' }

    after(:example) { travel_back }

    def post_request(params)
      post '/api/eform/validate', params: params
    end

    describe 'auth token' do
      it 'is required' do
        post_request default_params.merge({ token: 'no_token' })
        expect(response.status).to eq(401)
      end
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
