class EformController < ApiController
  before_action :require_token

  def validate
    version_major, version_minor = params[:version].split('.')
    form_template = FormTemplate.find_by!(identifier: params[:identifier], version_major: version_major, version_minor: version_minor)

    xsd_schema = Nokogiri::XML::Schema(form_template.xsd_schema)
    form_xml = Nokogiri::XML(params[:data]) { |config| config.strict }

    validation_errors = xsd_schema.validate(form_xml)
    render json: { valid: validation_errors.empty?, errors: validation_errors.map(&:message) }
  rescue Nokogiri::XML::SyntaxError
    render json: { valid: false, errors: ['Malformed XML'] }
  end

  private

  def require_token
    render_bad_request('No credentials') and return if params[:token].blank?
    authenticator.verify_token(params[:token])
  end
end
