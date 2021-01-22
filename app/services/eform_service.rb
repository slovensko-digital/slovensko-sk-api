class EformService
  def initialize(proxy)
    @upvs = proxy
  end

  def fetch_all_form_template_ids
    service = ServiceClassEnum::EFORM_FINDFORMTEMPLATES_SOAP_V_1_0
    request = factory.create_find_form_templates_req

    @upvs.ez.call_service(service, request).form_templates.value.form_template_id
  end

  def fetch_form_template_status(identifier, version)
    service = ServiceClassEnum::EFORM_GETFORMTEMPLATESTATUS_SOAP_V_1_0
    request = factory.create_get_form_template_status_req

    request.form_template = factory.create_get_form_template_status_req_form_template(form_template_id(identifier, version))

    @upvs.ez.call_service(service, request).form_status.value
  end

  # TODO rename - this reads as "fetch XML schema definition schema"
  def fetch_xsd_schema(identifier, version)
    service = ServiceClassEnum::EFORM_GETRELATEDDOCUMENTBYTYPE_SOAP_V_1_0
    request = factory.create_get_related_document_by_type_req

    request.form_template = factory.create_get_related_document_by_type_req_form_template(form_template_id(identifier, version))
    request.related_document_type = factory.create_get_related_document_by_type_req_related_document_type('CLS_F_XSD_EDOC')
    request.related_document_language = factory.create_get_related_document_by_type_req_related_document_language('sk')

    @upvs.ez.call_service(service, request).related_document.value
  end

  private

  mattr_reader :factory, default: sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.ObjectFactory.new

  java_import sk.gov.schemas.servicebus.service._1.ServiceClassEnum

  def form_template_id(identifier, version)
    major, minor = version.split('.', 2).map { |n| Integer(n, 10) }

    form_template_id = factory.create_form_template_id
    form_template_id.identifier = factory.create_form_template_id_identifier(identifier)

    form_version = factory.create_eform_version
    form_version.major = major
    form_version.minor = minor

    form_template_id.version = factory.create_form_template_id_version(form_version)
    form_template_id
  end

  private_constant *constants(false)
end
