class EformController < ApiController
  before_action { authenticate }

  before_action { render_bad_request('No form identifier') if params[:identifier].blank? }
  before_action { render_bad_request('No form version') if params[:version].blank? }
  before_action { render_bad_request('No form data') if params[:data].blank? }

  rescue_from(ActiveRecord::RecordNotFound) { render_not_found("Form #{params[:identifier]} version #{params[:version]} not found") }
  rescue_from(Nokogiri::XML::SyntaxError) { render_bad_request('Malformed form data') }

  def validate
    version_major, version_minor = params[:version].split('.', 2)
    form_template = FormTemplate.find_by!(identifier: params[:identifier], version_major: version_major, version_minor: version_minor)

    xsd_schema = Nokogiri::XML::Schema(form_template.xsd_schema)
    form_data = Nokogiri::XML(params[:data]) { |config| config.strict }

    errors = xsd_schema.validate(form_data)

    render json: { valid: errors.none?, errors: errors.map(&:message).presence }.compact
  end
end
