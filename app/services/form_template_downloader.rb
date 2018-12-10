class FormTemplateDownloader
  java_import "sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.ObjectFactory"
  java_import "sk.gov.schemas.servicebus.service._1.ServiceClassEnum"

  def initialize(upvs_proxy)
    @ez = upvs_proxy.ez
    @object_factory = ObjectFactory.new
  end

  def download_form_templates
    service = ServiceClassEnum::EFORM_FINDFORMTEMPLATES_SOAP_V_1_0
    request = @object_factory.create_find_form_templates_req

    form_templates = @ez.call_service(service, request).form_templates.value.form_template_id

    form_templates.each do |ft|
      FormTemplate.find_or_create_by!(
        identifier: ft.identifier.value,
        version_major: ft.version.value.major,
        version_minor: ft.version.value.minor
      )
    end
  end

  def download_xsd_schema(form_template)
    xsd_schema = FormTemplateRelatedDocument.find_or_initialize_by(
      form_template: form_template,
      language: 'sk',
      document_type: 'CLS_F_XSD_EDOC'
    )

    return unless xsd_schema.new_record?

    service = ServiceClassEnum::EFORM_GETRELATEDDOCUMENTBYTYPE_SOAP_V_1_0
    form_template_id = EformObject.build_from_form_template(form_template)

    request = @object_factory.create_get_related_document_by_type_req
    request.form_template = @object_factory.create_get_related_document_by_type_req_form_template(form_template_id)
    request.related_document_language = @object_factory.create_get_related_document_by_type_req_related_document_language(xsd_schema.language)
    request.related_document_type = @object_factory.create_get_related_document_by_type_req_related_document_type(xsd_schema.document_type)

    eform_related_document = @ez.call_service(service, request).related_document.value

    xsd_schema.data = eform_related_document.data.value.to_s
    xsd_schema.save!
  rescue Java::JavaxXmlWsSoap::SOAPFaultException => e
    raise e unless e.message == '06000796' # Skip 'not found' errors
  end
end
