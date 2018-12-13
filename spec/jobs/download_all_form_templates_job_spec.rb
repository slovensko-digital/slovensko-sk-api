require 'rails_helper'

RSpec.describe DownloadAllFormTemplatesJob, :upvs, type: :job do
  let(:eform_proxy) { UpvsEnvironment.eform_proxy }

  describe '#perform' do
    before(:all) do
      @limited_response = UpvsEnvironment.eform_proxy.fetch_all_form_template_ids.first(3)
    end

    before(:each) do
      expect(eform_proxy).to receive(:fetch_all_form_template_ids).and_return(@limited_response)
    end

    it 'enqueues DownloadFormTemplateJobs' do
      expect{ subject.perform }.to have_enqueued_job(DownloadFormTemplateJob).exactly(3).times
    end
  end
end
