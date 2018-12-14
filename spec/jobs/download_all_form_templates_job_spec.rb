require 'rails_helper'

RSpec.describe DownloadAllFormTemplatesJob, :upvs, type: :job do
  let(:eform_service) { UpvsEnvironment.eform_service }

  describe '#perform' do
    before(:all) do
      @limited_response = UpvsEnvironment.eform_service.fetch_all_form_template_ids.first(3)
    end

    before(:each) do
      expect(eform_service).to receive(:fetch_all_form_template_ids).and_return(@limited_response)
    end

    it 'enqueues DownloadFormTemplateJobs' do
      expect{ subject.perform }.to have_enqueued_job(DownloadFormTemplateJob).exactly(3).times
    end
  end
end
