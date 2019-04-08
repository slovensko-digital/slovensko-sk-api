require_relative '../../config/environment'

ez = UpvsEnvironment.upvs_proxy(assertion: nil).ez

service = sk.gov.schemas.servicebus.service._1.ServiceClassEnum::EFORM_FINDFORMTEMPLATES_SOAP_V_1_0
request = sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.FindFormTemplatesReq.new

form_templates = ez.call_service(service, request).get_form_templates.get_value.get_form_template_id

form_templates.each do |ft|
  puts "#{ft.get_identifier.get_value} #{ft.get_version.get_value.get_major}.#{ft.get_version.get_value.get_minor}"
end
