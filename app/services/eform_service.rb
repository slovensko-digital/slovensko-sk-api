class EformService
  def initialize(upvs_proxy)
    @ez = upvs_proxy.ez
    @object_factory = Eform.object_factory
  end

  def fetch_all_form_template_ids
    service = Eform::SERVICES::EFORM_FINDFORMTEMPLATES_SOAP_V_1_0
    request = @object_factory.create_find_form_templates_req

    @ez.call_service(service, request).form_templates.value.form_template_id
  end

  def fetch_xsd_schema_for(form_template)
    service = Eform::SERVICES::EFORM_GETRELATEDDOCUMENTBYTYPE_SOAP_V_1_0
    form_template_id = Eform.build_form_template_id(form_template)

    request = @object_factory.create_get_related_document_by_type_req
    request.form_template = @object_factory.create_get_related_document_by_type_req_form_template(form_template_id)
    request.related_document_language = @object_factory.create_get_related_document_by_type_req_related_document_language('sk')
    request.related_document_type = @object_factory.create_get_related_document_by_type_req_related_document_type('CLS_F_XSD_EDOC')

    @ez.call_service(service, request).related_document.value
  rescue Java::JavaxXmlWsSoap::SOAPFaultException => e
    raise e unless e.message == '06000796' # Skip 'not found' errors
  end
end
