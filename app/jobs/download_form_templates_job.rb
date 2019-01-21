class DownloadFormTemplatesJob < ApplicationJob
  def perform(force: false)
    Heartbeat.find_or_create_by(name: self.class.name).touch

    eform_service = UpvsEnvironment.eform_service
    eform_service.fetch_all_form_template_ids.each do |template_id|
      identifier, version_major, version_minor = template_id.identifier.value, template_id.version.value.major, template_id.version.value.minor
      next if FormTemplate.exists?(identifier: identifier, version_major: version_major, version_minor: version_minor) && !force
      DownloadFormTemplateJob.perform_later(identifier, version_major, version_minor)
    end
  end
end
