class EformController < ApiController
  def validate
    version_major, version_minor = params[:version].split('.')
    form_template = FormTemplate.find_by!(identifier: params[:identifier], version_major: version_major, version_minor: version_minor)

    xsd_schema = Nokogiri::XML::Schema(form_template.xsd_schema)
    form_xml = Nokogiri::XML(params[:data])

    validation_errors = xsd_schema.validate(form_xml)
    render json: { valid: validation_errors.empty?, errors: validation_errors.map(&:message) }
  end
end
