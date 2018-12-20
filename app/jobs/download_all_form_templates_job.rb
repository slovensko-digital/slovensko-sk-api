class DownloadAllFormTemplatesJob < ApplicationJob
  def perform
    Heartbeat.find_or_create_by(name: self.class.name).touch

    eform_service = UpvsEnvironment.eform_service
    eform_service.fetch_all_form_template_ids.each do |template_id|
      DownloadFormTemplateJob.perform_later(template_id.identifier.value, template_id.version.value.major, template_id.version.value.minor)
    end
  end
end
