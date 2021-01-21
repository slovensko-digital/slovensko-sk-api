class DownloadFormTemplateJob < ApplicationJob
  def perform(identifier, version_major, version_minor)
    eform_service = UpvsEnvironment.eform_service(sub: ENV.fetch('EFORM_SYNC_SUBJECT'))

    FormTemplate.transaction do
      template = FormTemplate.find_or_create_by(identifier: identifier, version_major: version_major, version_minor: version_minor)
      schema = eform_service.fetch_xsd_schema(identifier, "#{version_major}.#{version_minor}")

      return unless schema.present?

      FormTemplateRelatedDocument.create_with(data: schema.data.value.to_s).find_or_create_by(
        form_template: template,
        language: schema.meta_data.value.language.value,
        document_type: schema.meta_data.value.type.value
      )
    rescue javax.xml.ws.soap.SOAPFaultException => e
      raise e unless e.message == '06000796'
    end
  end
end
