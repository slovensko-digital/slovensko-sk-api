class EformProxy
  SERVICES = sk.gov.schemas.servicebus.service._1.ServiceClassEnum
  attr_reader :object_factory

  def initialize(upvs_proxy)
    @ez = upvs_proxy.ez
    @object_factory = sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.ObjectFactory.new
  end

  def fetch_all_form_template_ids
    service = SERVICES::EFORM_FINDFORMTEMPLATES_SOAP_V_1_0
    request = @object_factory.create_find_form_templates_req

    @ez.call_service(service, request).form_templates.value.form_template_id
  end

  def fetch_xsd_schema_for(form_template)
    service = SERVICES::EFORM_GETRELATEDDOCUMENTBYTYPE_SOAP_V_1_0
    form_template_id = build_form_template_id_from(form_template)

    request = @object_factory.create_get_related_document_by_type_req
    request.form_template = @object_factory.create_get_related_document_by_type_req_form_template(form_template_id)
    request.related_document_language = @object_factory.create_get_related_document_by_type_req_related_document_language('sk')
    request.related_document_type = @object_factory.create_get_related_document_by_type_req_related_document_type('CLS_F_XSD_EDOC')

    @ez.call_service(service, request).related_document.value
  rescue Java::JavaxXmlWsSoap::SOAPFaultException => e
    raise e unless e.message == '06000796' # Skip 'not found' errors
  end

  private

  def build_form_template_id_from(form_template)
    form_template_id = @object_factory.create_form_template_id
    form_template_id.identifier = @object_factory.create_form_template_id_identifier(form_template.identifier)

    form_version = @object_factory.create_eform_version
    form_version.major = form_template.version_major
    form_version.minor = form_template.version_minor

    form_template_id.version = @object_factory.create_form_template_id_version(form_version)
    form_template_id
  end
end
