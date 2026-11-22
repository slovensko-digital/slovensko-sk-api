class EformController < ApiController
  before_action { authenticate(allow_sub: true) }

  rescue_from ActiveRecord::RecordNotFound, with: -> { render_not_found(:template) }
  rescue_from Nokogiri::XML::SyntaxError, with: -> { render_bad_request(:invalid, :form) }

  rescue_from_soap_fault { |code| render_not_found(:template) if code == "06000798" }

  def status
    identifier, version = params.require([ :identifier, :version ])

    render json: { status: eform_service(**upvs_identity).fetch_form_template_status(identifier, version) }
  end

  def validate
    identifier, version, form = params.require([ :identifier, :version, :form ])

    # TODO remove -> see notes in FormTemplate model
    version_major, version_minor = version.split(".", 2)

    template = FormTemplate.find_by!(identifier:, version_major:, version_minor:)

    if template.xsd_schema.present?
      schema = Nokogiri::XML::Schema(template.xsd_schema)
      document = Nokogiri::XML(form, &:strict)

      errors = schema.validate(document)

      render json: { valid: errors.none?, errors: errors.map(&:message).presence }.compact
    else
      render_not_found(:schema)
    end
  end

  def form_template_related_document
    identifier, version, type = params.require([ :identifier, :version, :type ])

    # TODO remove -> see notes in FormTemplate model
    version_major, version_minor = *version.split(".", 2)

    document = FormTemplate.find_by!(identifier:, version_major:, version_minor:).related_document(type)

    if document.present?
      render json: { document: Base64.encode64(document) }
    else
      render_not_found(:template_related_document)
    end
  end

  def form_template_metadata
    identifier, version = params.require([ :identifier, :version ])

    @response = eform_service(**upvs_identity).fetch_form_template_metadata(identifier, version)
  end

  def form_package
    identifier, version = params.require([ :identifier, :version ])

    form_package_data = eform_service(**upvs_identity).fetch_form_package(identifier, version)

    render json: { data: Base64.strict_encode64(String.from_java_bytes(form_package_data).force_encoding("UTF-8")) }
  rescue Java::JavaxXmlWsSoap::SOAPFaultException => e
    if e.message == "Nie je možné vygenerovať vzor formulára."
      render_not_found(:template)
    else
      raise e
    end
  end
end
