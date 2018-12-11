require 'rails_helper'

RSpec.describe DownloadFormTemplateJob, :upvs, type: :job do
  describe '#perform' do
    let(:form_template) { create(:form_template) }

    def subject_perform
      subject.perform(form_template.identifier, form_template.version_major, form_template.version_minor)
    end

    it 'downloads form template' do
      expect{ subject_perform }.to change{ FormTemplate.count }.from(0).to(1)
    end

    it 'downloads xsd schema' do
      expect{ subject_perform }.to change{ FormTemplateRelatedDocument.count }.from(0).to(1)

      xsd_schema = FormTemplateRelatedDocument.last
      expect(xsd_schema).to have_attributes(form_template: form_template, language: 'sk', document_type: 'CLS_F_XSD_EDOC')
    end
  end
end
