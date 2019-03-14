class ApiController < ActionController::API
  rescue_from JWT::DecodeError do |error|
    if error.message == 'Nil JSON web token'
      render_bad_request(:no_credentials)
    else
      render_unauthorized
    end
  end

  wrappers = [
    com.google.common.util.concurrent.ExecutionError,
    com.google.common.util.concurrent.UncheckedExecutionException,
    java.util.concurrent.ExecutionException,
    java.lang.reflect.UndeclaredThrowableException,
  ]

  rescue_from(*wrappers) { |error| rescue_with_handler(error.cause) || raise }

  rescue_from(java.net.SocketTimeoutException, java.util.concurrent.TimeoutException) { render_request_timeout }
  rescue_from(javax.xml.ws.soap.SOAPFaultException) { |error| render_request_timeout if soap_timeout?(error) }

  private

  def authenticate(**options)
    Environment.api_token_authenticator.verify_token(authenticity_token, options)
  end

  def authenticity_token
    (ActionController::HttpAuthentication::Token.token_and_options(request)&.first || params[:token])&.squish.presence
  end

  def soap_timeout?(error)
    error.message =~ /(connect|read) timed out/i
  end

  def render_bad_request(key, **options)
    render status: :bad_request, json: { message: I18n.t("bad_request.#{key}", options) }
  end

  def render_unauthorized
    self.headers['WWW-Authenticate'] = 'Token realm="API"'
    render status: :unauthorized, json: { message: I18n.t(:unauthorized) }
  end

  def render_not_found(key, **options)
    render status: :not_found, json: { message: I18n.t("not_found.#{key}", options) }
  end

  def render_request_timeout
    render status: :request_timeout, json: { message: I18n.t(:request_timeout) }
  end

  def render_payload_too_large
    render status: :payload_too_large, json: { message: I18n.t(:payload_too_large) }
  end

  def render_too_many_requests
    render status: :too_many_requests, json: { message: I18n.t(:too_many_requests) }
  end

  def render_internal_server_error
    render status: :internal_server_error, json: { message: I18n.t(:internal_server_error) }
  end
end
