require_relative '../../config/environment'

ez_client = UpvsEnvironment.upvs_proxy(nil).ez_client
form_templates = ez_client.find_form_templates.get_form_templates.get_value.get_form_template_id

form_templates.each do |ft|
  puts "#{ft.get_identifier.get_value} #{ft.get_version.get_value.get_major}.#{ft.get_version.get_value.get_minor}"
end
