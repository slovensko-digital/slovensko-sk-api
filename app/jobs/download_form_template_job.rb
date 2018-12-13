class DownloadFormTemplateJob < ApplicationJob
  def perform(identifier, version_major, version_minor)
    eform_proxy = UpvsEnvironment.eform_proxy
    form_template = FormTemplate.find_or_initialize_by(identifier: identifier, version_major: version_major, version_minor: version_minor)
    xsd_schema = nil

    eform_xsd_schema = eform_proxy.fetch_xsd_schema_for(form_template)

    if eform_xsd_schema.present?
      xsd_schema = FormTemplateRelatedDocument.find_or_initialize_by(
        form_template: form_template,
        language: eform_xsd_schema.meta_data.value.language.value,
        document_type: eform_xsd_schema.meta_data.value.type.value
      )
      xsd_schema.data = eform_xsd_schema.data.value.to_s
    end

    ActiveRecord::Base.transaction do
      form_template.save!
      xsd_schema.save! if xsd_schema.present?
    end
  end
end
