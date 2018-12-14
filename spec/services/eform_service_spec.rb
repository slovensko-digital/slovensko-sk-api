require 'rails_helper'

RSpec.describe EformService, :upvs do
  let(:properties) { UpvsEnvironment.properties }
  let(:upvs) { UpvsProxy.new(properties) }
  let(:ez) { upvs.ez }
  let(:object_factory) { described_class.new(upvs).object_factory }

  subject { described_class.new(upvs) }

  describe '#fetch_all_form_template_ids' do
    it 'calls ez with right arguments' do
      response = double
      allow(response).to receive_message_chain("form_templates.value.form_template_id")

      service_class = described_class::SERVICES::EFORM_FINDFORMTEMPLATES_SOAP_V_1_0
      request = object_factory.create_find_form_templates_req

      expect(ez).to receive(:call_service).with(service_class, instance_of(request.class)).and_return(response)

      subject.fetch_all_form_template_ids
    end
  end

  describe '#fetch_xsd_schema_for' do
    let(:form_template) { create(:form_template, identifier: "App.GeneralAgenda", version_major: 1, version_minor: 9) }

    RSpec::Matchers.define :request_matching do |form_template|
      match do |request|
        expect(request).to be_instance_of(sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.GetRelatedDocumentByTypeReq)
        expect(request.form_template.value.identifier.value).to eq(form_template.identifier)
        expect(request.form_template.value.version.value.major).to eq(form_template.version_major)
        expect(request.form_template.value.version.value.minor).to eq(form_template.version_minor)

        expect(request.related_document_type.value).to eq('CLS_F_XSD_EDOC')
        expect(request.related_document_language.value).to eq('sk')
      end
    end

    it 'calls ez with right arguments' do
      response = double
      allow(response).to receive_message_chain("related_document.value")
      service_class = described_class::SERVICES::EFORM_GETRELATEDDOCUMENTBYTYPE_SOAP_V_1_0

      expect(ez).to receive(:call_service).with(service_class, request_matching(form_template)).and_return(response)

      subject.fetch_xsd_schema_for(form_template)
    end

    describe 'on error' do
      let (:fault) { double }

      it 'does not raise when the document does not exist' do
        expect(fault).to receive(:get_fault_string).and_return('06000796')
        expect(ez).to receive(:call_service).and_raise(Java::JavaxXmlWsSoap::SOAPFaultException.new(fault))

        expect { subject.fetch_xsd_schema_for(form_template) }.to_not raise_error
      end

      it 'breaks otherwise' do
        expect(fault).to receive(:get_fault_string).and_return('1234')
        expect(ez).to receive(:call_service).and_raise(Java::JavaxXmlWsSoap::SOAPFaultException.new(fault))

        expect { subject.fetch_xsd_schema_for(form_template) }.to raise_error(Java::JavaxXmlWsSoap::SOAPFaultException)
      end
    end
  end
end
