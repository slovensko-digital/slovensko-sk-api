require 'rails_helper'

RSpec.describe DownloadFormTemplatesJob, :upvs, type: :job do
  describe '#perform' do
    before(:context) do
      @response = UpvsEnvironment.eform_service.fetch_all_form_template_ids.first(3)
    end

    before(:example) do
      eform_service = double

      allow(UpvsEnvironment).to receive(:eform_service).and_return(eform_service)
      allow(eform_service).to receive(:fetch_all_form_template_ids).and_return(@response)
    end

    it 'enqueues DownloadFormTemplateJob for new templates by default' do
      FormTemplate.create(
        identifier: @response.first.identifier.value,
        version_major: @response.first.version.value.major,
        version_minor: @response.first.version.value.minor
      )

      expect { subject.perform }.to have_enqueued_job(DownloadFormTemplateJob).exactly(2).times
    end

    it 'enqueues DownloadFormTemplateJob for all templates when forced' do
      FormTemplate.create(
        identifier: @response.first.identifier.value,
        version_major: @response.first.version.value.major,
        version_minor: @response.first.version.value.minor
      )

      expect { subject.perform(force: true) }.to have_enqueued_job(DownloadFormTemplateJob).exactly(3).times
    end
  end
end
