RSpec::Matchers.define :eform_find_form_templates_request do
  match do |request|
    request.kind_of?(sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.FindFormTemplatesReq)
  end
end

RSpec::Matchers.define :eform_get_form_template_status_request do |identifier, version|
  match do |request|
    request.kind_of?(sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.GetFormTemplateStatusReq)
    request.form_template.value.identifier.value == identifier &&
    request.form_template.value.version.value.major == version.split('.').first.to_i &&
    request.form_template.value.version.value.minor == version.split('.').last.to_i
  end
end

RSpec::Matchers.define :eform_get_related_document_by_type_request do |identifier, version, type, language|
  match do |request|
    request.kind_of?(sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.GetRelatedDocumentByTypeReq)
    request.form_template.value.identifier.value == identifier &&
    request.form_template.value.version.value.major == version.split('.').first.to_i &&
    request.form_template.value.version.value.minor == version.split('.').last.to_i &&
    request.related_document_type.value == type &&
    request.related_document_language.value == language
  end
end
