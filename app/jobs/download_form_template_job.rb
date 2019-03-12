class DownloadFormTemplateJob < ApplicationJob
  def perform(identifier, version_major, version_minor)
    eform_service = UpvsEnvironment.eform_service
    form_template = FormTemplate.find_or_initialize_by(identifier: identifier, version_major: version_major, version_minor: version_minor)

    begin
      xsd_schema = eform_service.fetch_xsd_schema(form_template.identifier, form_template.version)
    rescue javax.xml.ws.soap.SOAPFaultException => e
      raise e unless e.message == '06000796'
    end

    if xsd_schema.present?
      related_document = FormTemplateRelatedDocument.find_or_initialize_by(
        form_template: form_template,
        language: xsd_schema.meta_data.value.language.value,
        document_type: xsd_schema.meta_data.value.type.value
      )
      related_document.data = xsd_schema.data.value.to_s
    end

    FormTemplate.transaction do
      form_template.save!
      related_document.save! if related_document.present?
    end
  end
end
