class EformController < ApiController
  before_action { authenticate(allow_ta: true) }

  before_action { render_bad_request(:no_form_identifier) if params[:identifier].blank? }
  before_action { render_bad_request(:no_form_version) if params[:version].blank? }

  before_action(only: :validate) { render_bad_request(:no_form_data) if params[:data].blank? }

  rescue_from(ActiveRecord::RecordNotFound) { render_not_found(:form_template, identifier: params[:identifier], version: params[:version]) }
  rescue_from(Nokogiri::XML::SyntaxError) { render_bad_request(:malformed_form_data) }

  # TODO consider some sort of rescue-from-soap-fault helper, the goal is not ot override soap fault rescue handler here but reuse the definition in api controller
  rescue_from javax.xml.ws.soap.SOAPFaultException do |error|
    logger.debug { error.full_message }

    if soap_timeout?(error)
      render_request_timeout
    elsif error.message == '06000798'
      render_not_found(:form_template, identifier: params[:identifier], version: params[:version])
    else
      render_internal_server_error
    end
  end

  def status
    status = UpvsEnvironment.eform_service.fetch_form_template_status(params[:identifier], params[:version])

    render json: { status: status }
  end

  def validate
    identifier, version_major, version_minor = params[:identifier], *params[:version].split('.', 2)
    form_template = FormTemplate.find_by!(identifier: identifier, version_major: version_major, version_minor: version_minor)

    if form_template.xsd_schema.present?
      xsd_schema = Nokogiri::XML::Schema(form_template.xsd_schema)
      form_data = Nokogiri::XML(params[:data]) { |config| config.strict }

      errors = xsd_schema.validate(form_data)

      render json: { valid: errors.none?, errors: errors.map(&:message).presence }.compact
    else
      render_not_found(:form_schema, identifier: params[:identifier], version: params[:version])
    end
  end
end
