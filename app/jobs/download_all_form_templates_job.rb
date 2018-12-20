class DownloadAllFormTemplatesJob < ApplicationJob
  def perform
    eform_service = UpvsEnvironment.eform_service
    eform_service.fetch_all_form_template_ids.each do |template_id|
      DownloadFormTemplateJob.perform_later(template_id.identifier.value, template_id.version.value.major, template_id.version.value.minor)
      Heartbeat.find_or_initialize_by(name: self.class.name).touch
    end
  end
end
