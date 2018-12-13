class DownloadAllFormTemplatesJob < ApplicationJob
  def perform
    eform_proxy = UpvsEnvironment.eform_proxy
    eform_proxy.fetch_all_form_template_ids.each do |template_id|
      DownloadFormTemplateJob.perform_later(template_id.identifier.value, template_id.version.value.major, template_id.version.value.minor)
    end
  end
end
