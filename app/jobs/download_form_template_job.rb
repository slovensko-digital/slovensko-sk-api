class DownloadFormTemplateJob < ApplicationJob
  def perform(identifier, version_major, version_minor)
    eform_service = UpvsEnvironment.eform_service(sub: ENV.fetch('EFORM_SYNC_SUBJECT'))

    FormTemplate.transaction do
      template = FormTemplate.find_or_create_by(identifier: identifier, version_major: version_major, version_minor: version_minor)

      xsd_schema = eform_service.fetch_form_related_document(identifier, "#{version_major}.#{version_minor}", 'CLS_F_XSD_EDOC')
      create_form_template_related_document(xsd_schema, template)

      xslt_sign_transformation = eform_service.fetch_form_related_document(identifier, "#{version_major}.#{version_minor}", 'CLS_F_XSLT_TXT_SGN')
      create_form_template_related_document(xslt_sign_transformation, template)

    rescue javax.xml.ws.soap.SOAPFaultException => e
      raise e unless e.message == '06000796'
    end
  end

  def create_form_template_related_document(document, template)
    return unless document.present?

    FormTemplateRelatedDocument.create_with(data: fix_document_data(document.data.value.to_s)).find_or_create_by(
      form_template: template,
      language: document.meta_data.value.language.value,
      document_type: document.meta_data.value.type.value
    )
  end

  def fix_document_data(document)
    document.force_encoding('UTF-8').gsub(/>\s*/, ">").gsub(/\s*</, "<")
  end
end
