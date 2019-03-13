require 'rails_helper'

RSpec.describe DownloadFormTemplateJob, :upvs, type: :job do
  describe '#perform' do
    let(:identifier) { 'App.GeneralAgenda' }

    it 'downloads form template' do
      expect { subject.perform(identifier, 1, 9) }.to change { FormTemplate.count }.from(0).to(1)

      form_template = FormTemplate.first

      expect(form_template).to have_attributes(identifier: identifier, version_major: 1, version_minor: 9)
    end

    it 'downloads XSD schema' do
      expect { subject.perform(identifier, 1, 9) }.to change { FormTemplateRelatedDocument.count }.from(0).to(1)

      form_template = FormTemplate.first
      xsd_schema = FormTemplateRelatedDocument.first

      expect(xsd_schema).to have_attributes(form_template: form_template, document_type: 'CLS_F_XSD_EDOC', language: 'sk')
    end

    context 'with form template already present' do
      pending 'updates form template'

      pending 'updates XSD schema'
    end

    context 'with form template not found' do
      let(:identifier) { 'App.UnknownAgenda' }

      it 'does not download form template' do
        expect { suppress(javax.xml.ws.soap.SOAPFaultException) { subject.perform(identifier, 1, 0) }}.not_to change { FormTemplate.count }
      end

      it 'raises error' do
        expect { subject.perform(identifier, 1, 0) }.to raise_error(javax.xml.ws.soap.SOAPFaultException) do |error|
          expect(error.message).to eq('06000798')
        end
      end
    end

    context 'with related document not found' do
      let(:identifier) { 'DCOM_eDemokracia_ZiadostOVydanieVolicskehoPreukazuFO_sk' }

      it 'downloads form template' do
        expect { subject.perform(identifier, 1, 0) }.to change { FormTemplate.count }.from(0).to(1)
      end

      it 'does not download XSD schema' do
        expect { subject.perform(identifier, 1, 0) }.not_to change { FormTemplateRelatedDocument.count }
      end

      it 'does not raise error' do
        expect { subject.perform(identifier, 1, 0) }.not_to raise_error
      end
    end
  end
end
