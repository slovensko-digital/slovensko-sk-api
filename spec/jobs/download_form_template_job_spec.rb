# TODO jobs should not be STS type specs -> eForm service is covered as STS spec in spec/services

require 'rails_helper'

RSpec.describe DownloadFormTemplateJob, :sts do
  before(:example) { stub_const('ENV', ENV.merge('EFORM_SYNC_SUBJECT' => corporate_body_subject)) }

  describe '#perform' do
    let(:identifier) { 'App.GeneralAgenda' }

    it 'downloads form template' do
      expect { subject.perform(identifier, 1, 9) }.to change { FormTemplate.count }.by(1)

      form_template = FormTemplate.first

      expect(form_template).to have_attributes(identifier: identifier, version_major: 1, version_minor: 9)
    end

    it 'downloads form schema' do
      expect { subject.perform(identifier, 1, 9) }.to change { FormTemplateRelatedDocument.count }.by(1)

      form_template = FormTemplate.first
      form_schema = FormTemplateRelatedDocument.first

      expect(form_schema).to have_attributes(form_template: form_template, document_type: 'CLS_F_XSD_EDOC', language: 'sk')
    end

    context 'with form template already present' do
      pending 'updates form template'

      pending 'updates form schema'
    end

    context 'with form template not found' do
      let(:identifier) { 'App.UnknownAgenda' }

      it 'does not download form template' do
        expect { suppress(javax.xml.ws.soap.SOAPFaultException) { subject.perform(identifier, 1, 0) }}.not_to change { FormTemplate.count }
      end

      it 'raises error' do
        expect { subject.perform(identifier, 1, 0) }.to raise_soap_fault_exception('06000798')
      end
    end

    context 'with form schema not found' do
      let(:identifier) { '36126624.Rozhodnutie.sk' }

      it 'downloads form template' do
        expect { subject.perform(identifier, 1, 8) }.to change { FormTemplate.count }.by(1)
      end

      it 'does not download form schema' do
        expect { subject.perform(identifier, 1, 8) }.not_to change { FormTemplateRelatedDocument.count }
      end

      it 'does not raise error' do
        expect { subject.perform(identifier, 1, 8) }.not_to raise_error
      end
    end
  end
end
