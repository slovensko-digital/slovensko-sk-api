class ApiController < ActionController::API
  self.abstract!

  include ActionController::MimeResponds

  class_attribute :soap_fault_handler, default: Proc.new {}

  def self.rescue_from_soap_fault(&handler)
    self.soap_fault_handler = handler
  end

  before_action(:set_default_format)
  before_action(:verify_request_body)
  before_action(:verify_format)

  rescue_from ActionController::ParameterMissing do |error|
    render_bad_request(:missing, error.param)
  end

  rescue_from ActionController::UnknownFormat do
    render_not_acceptable
  end

  rescue_from JWT::DecodeError do |error|
    logger.debug { error.full_message }

    if error.message == 'Nil JSON web token'
      render_bad_request(:missing, :credentials)
    else
      render_unauthorized
    end
  end

  rescue_from java.io.IOException do |error|
    logger.debug { error.full_message }

    if error.message =~ /keystore resource/i
      render_service_unavailable_error(:sts)
    else
      render_internal_server_error
    end
  end

  rescue_from java.security.UnrecoverableKeyException, javax.xml.ws.WebServiceException, org.apache.cxf.ws.policy.PolicyException, org.apache.wss4j.common.ext.WSSecurityException, org.springframework.beans.BeansException do |error|
    logger.debug { error.full_message }

    render_service_unavailable_error(:sts)
  end

  rescue_from javax.xml.ws.soap.SOAPFaultException do |error|
    logger.debug { error.full_message }

    case error.message
    when /\A\d+\z/ then instance_exec(error.message, &soap_fault_handler) || render_service_unavailable_error(:unknown_error, { code: error.message })
    when /connection refused/i then render_service_unavailable_error(:connection_refused)
    when /timed out/i then render_request_timeout
    else
      # unable to determine failure from SOAP fault
      rescue_with_handler(error.cause) || render_service_unavailable_error(:unknown_error)
    end
  end

  private

  def authenticate(**options)
    self.upvs_identity = Environment.api_token_authenticator.verify_token(authenticity_token, options)
  end

  # TODO drop support of params[:token]
  def authenticity_token
    (ActionController::HttpAuthentication::Token.token_and_options(request)&.first || params[:token])&.squish.presence
  end

  def action_scope
    [controller_path, action_name].join('/')
  end

  def set_default_format(value = :json)
    request.format = Mime::Type.lookup(request.accept).symbol || value
  end

  def verify_format
    respond_to(:json)
  end

  def require_request_body?
    request.method_symbol.in?([:post, :patch, :put])
  end

  def verify_request_body
    if require_request_body?
      render_unsupported_media_type if request.content_mime_type.symbol != :json
    else
      # TODO apparently Rails test framework always sends application/x-www-form-urlencoded with no body (params: {}, as: nil) in non-get requests which is just weird and hence ignored here
      return if request.form_data? && request.raw_post.empty? if Rails.env.test?
      return render_bad_request(:redundant, :body) unless request.body.tap(&:rewind).eof?
      return render_bad_request(:redundant, 'Content-Type') if request.content_type
    end
  end

  # TODO can not #rescue_from this error yet, see https://github.com/rails/rails/issues/38285 and https://github.com/rails/rails/issues/34244#issuecomment-433365579
  def process_action(*)
    super
  rescue ActionDispatch::Http::Parameters::ParseError
    render_bad_request(:invalid, 'JSON')
  end

  def upvs_identity
    @upvs_identity || raise('Not authenticated')
  end

  def upvs_identity=(value)
    raise('Already authenticated') if @upvs_identity
    @upvs_identity = { sub: value.first, obo: value.last }
  end

  def upvs_fault(error)
    return if error.nil?
    return upvs_fault(error.cause) unless error.respond_to?(:fault_info)
    case fault = error.fault_info
    when org.datacontract.schemas._2004._07.anasoft_edesk.EDeskFault then { code: fault.code&.value, reason: fault.code&.reason }
    when sk.gov.schemas.identity.service._1.IamFault then { code: fault.fault_code.first, reason: fault.fault_message.first }
    else
      raise 'Unknown fault'
    end
  end

  delegate :cep_signer, :edesk_service, :eform_service, :iam_repository, :sktalk_receiver, :usr_service, to: UpvsEnvironment

  def render_bad_request(key, param, fault = nil)
    param = param.to_s.humanize(capitalize: false, keep_id_suffix: true) if param.is_a?(Symbol)
    render status: :bad_request, json: { message: translate("bad_request.#{key}", param: param).upcase_first, fault: fault }.compact
  end

  def render_unauthorized
    self.headers['WWW-Authenticate'] = 'Token realm="API"'
    render status: :unauthorized, json: { message: translate(:unauthorized) }
  end

  def render_not_found(resource)
    render status: :not_found, json: { message: translate(:not_found, resource: resource.to_s.humanize(capitalize: false, keep_id_suffix: true)).upcase_first }
  end

  def render_not_acceptable
    render status: :not_acceptable, json: { message: translate(:not_acceptable) }
  end

  def render_request_timeout
    render status: :request_timeout, json: { message: translate(:request_timeout) }
  end

  def render_conflict(key)
    render status: :conflict, json: { message: translate("conflict.#{key}") }
  end

  def render_payload_too_large
    render status: :payload_too_large, json: { message: translate(:payload_too_large) }
  end

  def render_unsupported_media_type
    render status: :unsupported_media_type, json: { message: translate(:unsupported_media_type) }
  end

  def render_unprocessable_entity(key)
    render status: :unprocessable_entity, json: { message: translate("unprocessable_entity.#{key}") }
  end

  def render_too_many_requests
    render status: :too_many_requests, json: { message: translate(:too_many_requests) }
  end

  def render_internal_server_error
    render status: :internal_server_error, json: { message: translate(:internal_server_error) }
  end

  def render_service_unavailable_error(key, fault = nil)
    render status: :service_unavailable, json: { message: translate("service_unavailable.#{key}"), fault: fault }.compact
  end

  delegate :translate, to: I18n
end
