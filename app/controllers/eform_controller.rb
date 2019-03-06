class EformController < ApiController
  before_action { authenticate(allow_ta: true) }

  before_action { render_bad_request(:no_form_identifier) if params[:identifier].blank? }
  before_action { render_bad_request(:no_form_version) if params[:version].blank? }
  before_action { render_bad_request(:no_form_data) if params[:data].blank? }

  rescue_from(ActiveRecord::RecordNotFound) { render_not_found(:form_identifier_with_version, identifier: params[:identifier], version: params[:version]) }
  rescue_from(Nokogiri::XML::SyntaxError) { render_bad_request(:malformed_form_data) }

  def validate
    version_major, version_minor = params[:version].split('.', 2)
    form_template = FormTemplate.find_by!(identifier: params[:identifier], version_major: version_major, version_minor: version_minor)

    xsd_schema = Nokogiri::XML::Schema(form_template.xsd_schema)
    form_data = Nokogiri::XML(params[:data]) { |config| config.strict }

    errors = xsd_schema.validate(form_data)

    render json: { valid: errors.none?, errors: errors.map(&:message).presence }.compact
  end
end
