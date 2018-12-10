require 'rails_helper'

java_import "sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.ObjectFactory"
java_import "sk.gov.schemas.servicebus.service._1.ServiceClassEnum"

RSpec.describe FormTemplateDownloader, :model, :upvs do
  let(:properties) { UpvsEnvironment.properties }
  let(:upvs) { UpvsProxy.new(properties) }
  let(:ez) { upvs.ez }
  let(:object_factory) { ObjectFactory.new }

  subject { described_class.new(upvs) }

  describe '#download_form_templates' do
    let(:response) do
      response = ez.call_service(ServiceClassEnum::EFORM_FINDFORMTEMPLATES_SOAP_V_1_0, object_factory.create_find_form_templates_req)
      array_of_form_template_id = object_factory.create_array_of_form_template_id
      response.form_templates.value.form_template_id.first(3).each { |fti| array_of_form_template_id.form_template_id.add(fti) }
      response.form_templates = object_factory.create_find_form_templates_res_form_templates(array_of_form_template_id)
      response
    end

    it 'calls ez with right arguments' do
      service_class = ServiceClassEnum::EFORM_FINDFORMTEMPLATES_SOAP_V_1_0
      request = object_factory.create_find_form_templates_req

      expect(ez).to receive(:call_service).with(service_class, instance_of(request.class)).and_return(response)

      subject.download_form_templates
    end

    it 'downloads all form templates' do
      expect(ez).to receive(:call_service).and_return(response)
      expect { subject.download_form_templates }.to change{ FormTemplate.count }.from(0).to(3)
    end

    it 'only downloads new templates' do
      expect(ez).to receive(:call_service).twice.and_return(response)
      expect { subject.download_form_templates }.to change{ FormTemplate.count }.from(0).to(3)
      expect { subject.download_form_templates }.to_not change{ FormTemplate.count }
    end
  end

  describe '#download_xsd_schema' do
    let(:form_template) { create(:form_template, identifier: "App.GeneralAgenda", version_major: 1, version_minor: 9) }

    let(:response) do
      form_template_id = EformObject.build_from_form_template(form_template)
      service = ServiceClassEnum::EFORM_GETRELATEDDOCUMENTBYTYPE_SOAP_V_1_0

      request = object_factory.create_get_related_document_by_type_req
      request.form_template = object_factory.create_get_related_document_by_type_req_form_template(form_template_id)
      request.related_document_language = object_factory.create_get_related_document_by_type_req_related_document_language("sk")
      request.related_document_type = object_factory.create_get_related_document_by_type_req_related_document_type("CLS_F_XSD_EDOC")

      ez.call_service(service, request)
    end

    RSpec::Matchers.define :matching_request do |form_template|
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
      service_class = ServiceClassEnum::EFORM_GETRELATEDDOCUMENTBYTYPE_SOAP_V_1_0

      expect(ez).to receive(:call_service).with(service_class, matching_request(form_template)).and_return(response)

      subject.download_xsd_schema(form_template)
    end

    it 'downloads xsd schema as related document' do
      expect(ez).to receive(:call_service).and_return(response)

      expect { subject.download_xsd_schema(form_template) }.to change{ FormTemplateRelatedDocument.count }.from(0).to(1)
      expect(FormTemplateRelatedDocument.last).to have_attributes(form_template: form_template, language: 'sk', document_type: 'CLS_F_XSD_EDOC')
    end

    describe 'on error' do
      let (:fault) { double }

      it 'does not raise when the document does not exist' do
        expect(fault).to receive(:get_fault_string).and_return('06000796')
        expect(ez).to receive(:call_service).and_raise(Java::JavaxXmlWsSoap::SOAPFaultException.new(fault))

        expect { subject.download_xsd_schema(form_template) }.to_not raise_error
      end

      it 'breaks otherwise' do
        expect(fault).to receive(:get_fault_string).and_return('1234')
        expect(ez).to receive(:call_service).and_raise(Java::JavaxXmlWsSoap::SOAPFaultException.new(fault))

        expect { subject.download_xsd_schema(form_template) }.to raise_error(Java::JavaxXmlWsSoap::SOAPFaultException)
      end
    end
  end
end
