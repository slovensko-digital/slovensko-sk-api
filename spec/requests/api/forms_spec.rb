require 'rails_helper'

RSpec.describe 'Form API' do
  before(:each) do
    create(:form_template_related_document, :general_agenda_xsd_schema)
  end

  let(:response_object) { JSON.parse(response.body) }

  valid_form_xml = <<~HEREDOC
    <GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.7" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <subject>some subject</subject>
      <text>some text</text>
    </GeneralAgenda>
  HEREDOC

  describe 'POST /api/forms/validate' do
    describe 'when form data is valid' do
      it 'returns validation result' do
        post '/api/forms/validate', params: { identifier: 'App.GeneralAgenda', version: '1.7', data: valid_form_xml }
        expect(response_object["valid"]).to eq(true)
        expect(response_object["errors"]).to be_blank

      end
    end

    describe 'when form data is invalid' do
      invalid_form_xml = <<~HEREDOC
        <InvalidForm>
        </InvalidForm>
      HEREDOC

      it 'lists validation errors' do
        post '/api/forms/validate', params: { identifier: 'App.GeneralAgenda', version: '1.7', data: invalid_form_xml }
        expect(response_object["valid"]).to eq(false)
        puts response_object["errors"]
        expect(response_object["errors"]).to be_present
      end
    end

    describe 'when parameters are missing' do
      pending 'returns 400 with a message'
    end

    describe 'when form or xsd schema is not found' do
      pending 'returns 400 with a message'
    end
  end
end
