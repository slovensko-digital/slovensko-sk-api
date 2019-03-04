class ApiController < ActionController::API
  rescue_from JWT::DecodeError do |error|
    if error.message == 'Nil JSON web token'
      render_bad_request(:no_credentials)
    else
      render_unauthorized
    end
  end

  rescue_from java.lang.Throwable do |error|
    error = unwrap_error(error)

    if timeout_error?(error)
      render_request_timeout
    else
      render_internal_server_error
    end
  end

  private

  def authenticate(scope: nil)
    Environment.api_token_authenticator.verify_token(authenticity_token, obo: scope.present?, scope: scope)
  end

  def authenticity_token
    (ActionController::HttpAuthentication::Token.token_and_options(request)&.first || params[:token])&.squish.presence
  end

  def unwrap_error(error)
    wrappers = [
      com.google.common.util.concurrent.ExecutionError,
      com.google.common.util.concurrent.UncheckedExecutionException,
      java.util.concurrent.ExecutionException,
      java.lang.reflect.UndeclaredThrowableException,
    ]

    wrappers.find { |wrapper| error.is_a?(wrapper) } ? unwrap_error(error.cause) : error
  end

  def timeout_error?(error)
    return true if error.is_a?(java.net.SocketTimeoutException)
    return true if error.is_a?(java.util.concurrent.TimeoutException)
    true if error.is_a?(javax.xml.ws.soap.SOAPFaultException) && error.message =~ /(connect|read) timed out/i
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
