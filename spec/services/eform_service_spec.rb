require 'rails_helper'

RSpec.describe EformService, :upvs do
  let(:properties) { UpvsEnvironment.properties(assertion: nil) }
  let(:upvs) { UpvsProxy.new(properties) }

  subject { described_class.new(upvs) }

  before(:example) { cache_java_object_proxy!(upvs.ez) }

  describe '#fetch_all_form_template_ids' do
    it 'calls service with correct request' do
      response = double

      allow(response).to receive_message_chain(:form_templates, :value, :form_template_id)

      service = EformService::EFORM_FINDFORMTEMPLATES_SOAP_V_1_0
      request = eform_find_form_templates_request

      expect(upvs.ez).to receive(:call_service).with(service, request).and_return(response)

      subject.fetch_all_form_template_ids
    end

    it 'fetches form template identifiers' do
      expect(subject.fetch_all_form_template_ids).to all be_a(sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.FormTemplateID)
    end
  end

  describe '#fetch_form_template_status' do
    let(:identifier) { 'App.GeneralAgenda' }
    let(:version) { '1.9' }

    it 'calls service with correct request' do
      response = double

      allow(response).to receive_message_chain(:form_status, :value)

      service = EformService::EFORM_GETFORMTEMPLATESTATUS_SOAP_V_1_0
      request = eform_get_form_template_status_request(identifier, version)

      expect(upvs.ez).to receive(:call_service).with(service, request).and_return(response)

      subject.fetch_form_template_status(identifier, version)
    end

    it 'fetches form template status' do
      expect(subject.fetch_form_template_status(identifier, version)).to eq('Publikovaný')
    end

    it 'raises error if form template is not found' do
      expect { subject.fetch_xsd_schema('App.UnknownAgenda', '1.0') }.to raise_error(javax.xml.ws.soap.SOAPFaultException) do |error|
        expect(error.message).to eq('06000798')
      end
    end
  end

  describe '#fetch_xsd_schema' do
    let(:identifier) { 'App.GeneralAgenda' }
    let(:version) { '1.9' }

    it 'calls service with correct request' do
      response = double

      allow(response).to receive_message_chain(:related_document, :value)

      service = EformService::EFORM_GETRELATEDDOCUMENTBYTYPE_SOAP_V_1_0
      request = eform_get_related_document_by_type_request(identifier, version, 'CLS_F_XSD_EDOC', 'sk')

      expect(upvs.ez).to receive(:call_service).with(service, request).and_return(response)

      subject.fetch_xsd_schema(identifier, version)
    end

    it 'fetches XSD schema' do
      expect(subject.fetch_xsd_schema(identifier, version)).to be_a(sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.RelatedDocument)
    end

    it 'raises error if form template is not found' do
      expect { subject.fetch_xsd_schema('App.UnknownAgenda', '1.0') }.to raise_error(javax.xml.ws.soap.SOAPFaultException) do |error|
        expect(error.message).to eq('06000798')
      end
    end

    it 'raises error if related document is not found' do
      expect { subject.fetch_xsd_schema('DCOM_eDemokracia_ZiadostOVydanieVolicskehoPreukazuFO_sk', '1.0') }.to raise_error(javax.xml.ws.soap.SOAPFaultException) do |error|
        expect(error.message).to eq('06000796')
      end
    end
  end
end
