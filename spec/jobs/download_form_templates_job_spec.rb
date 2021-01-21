# TODO jobs should not be STS type specs -> eForm service is covered as STS spec in spec/services

require 'rails_helper'

RSpec.describe DownloadFormTemplatesJob, :sts do
  before(:example) { stub_const('ENV', ENV.merge('EFORM_SYNC_SUBJECT' => corporate_body_subject)) }

  describe '#perform' do
    before(:context) do
      @response = UpvsEnvironment.eform_service(sub: corporate_body_subject).fetch_all_form_template_ids.first(3)
    end

    before(:example) do
      allow_any_instance_of(EformService).to receive(:fetch_all_form_template_ids).and_return(@response)
    end

    before(:example) do
      FormTemplate.create(
        identifier: @response.first.identifier.value,
        version_major: @response.first.version.value.major,
        version_minor: @response.first.version.value.minor
      )
    end

    it 'enqueues DownloadFormTemplateJob for new templates by default' do
      expect { subject.perform }.to have_enqueued_job(DownloadFormTemplateJob).exactly(2).times
    end

    it 'enqueues DownloadFormTemplateJob for all templates when forced' do
      expect { subject.perform(force: true) }.to have_enqueued_job(DownloadFormTemplateJob).exactly(3).times
    end
  end
end
