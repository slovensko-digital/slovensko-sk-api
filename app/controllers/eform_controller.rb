class EformController < ApiController
  before_action { authenticate(allow_sub: true) }

  rescue_from(ActiveRecord::RecordNotFound) { render_not_found(:template) }
  rescue_from(Nokogiri::XML::SyntaxError) { render_bad_request(:invalid, :form) }

  rescue_from_soap_fault { |code| render_not_found(:template) if code == '06000798' }

  def status
    identifier, version = params.require(:identifier), params.require(:version)

    render json: { status: eform_service(upvs_identity).fetch_form_template_status(identifier, version) }
  end

  def validate
    identifier, version, form = params.require(:identifier), params.require(:version), params.require(:form)

    # TODO remove -> see notes in FormTemplate model
    version_major, version_minor = version.split('.', 2)

    template = FormTemplate.find_by!(identifier: identifier, version_major: version_major, version_minor: version_minor)

    if template.xsd_schema.present?
      schema = Nokogiri::XML::Schema(template.xsd_schema)
      document = Nokogiri::XML(form) { |config| config.strict }

      errors = schema.validate(document)

      render json: { valid: errors.none?, errors: errors.map(&:message).presence }.compact
    else
      render_not_found(:schema)
    end
  end

  def form_template_related_document
    identifier, version, type = params.require(:identifier), params.require(:version), params.require(:type)

    # TODO remove -> see notes in FormTemplate model
    version_major, version_minor = *version.split('.', 2)

    document = FormTemplate.find_by!(identifier: identifier, version_major: version_major, version_minor: version_minor).related_document(type)

    document.present? ? (render status: :ok, json: { "document": Base64.encode64(document) }) : render_not_found(:template_related_document)
  end
end
