class ApiController < ActionController::API
  rescue_from JWT::DecodeError do |error|
    if error.message == 'Nil JSON web token'
      render_bad_request('No credentials')
    else
      render_unauthorized
    end
  end

  # TODO fix https://guides.rubyonrails.org/action_controller_overview.html#rescue-from
  # rescue_from StandardError, with: :render_internal_server_error unless Rails.env.development?

  # TODO this is not covered by specs, it may not work:
  rescue_from java.net.SocketTimeoutException, with: :render_request_timeout

  # TODO this does not rescue the raised cause again therefore the unwrapping may not work:
  wrappers = [
    com.google.common.util.concurrent.ExecutionError,
    com.google.common.util.concurrent.UncheckedExecutionException,
    java.util.concurrent.ExecutionException,
    java.lang.reflect.UndeclaredThrowableException,
  ]

  # clear last raised error so it does not tamper the cause of the unwrapped error on subsequent raise

  rescue_from(*wrappers) do |exception|
    $! = nil
    raise exception.cause
  end

  private

  def authenticate(scope: nil)
    Environment.api_token_authenticator.verify_token(authenticity_token, obo: scope.present?, scope: scope)
  end

  def authenticity_token
    (ActionController::HttpAuthentication::Token.token_and_options(request)&.first || params[:token])&.squish.presence
  end

  def render_bad_request(message)
    render status: :bad_request, json: { message: message }
  end

  def render_unauthorized
    self.headers['WWW-Authenticate'] = 'Token realm="API"'
    render status: :unauthorized, json: { message: 'Bad credentials' }
  end

  def render_not_found(message)
    render status: :not_found, json: { message: message }
  end

  def render_request_timeout
    render status: :request_timeout, json: { message: 'Operation timeout exceeded' }
  end

  def render_payload_too_large
    render status: :payload_too_large, json: { message: 'Message size limit exceeded' }
  end

  def render_too_many_requests
    render status: :too_many_requests, json: { message: 'Request rate limit exceeded' }
  end

  def render_internal_server_error
    render status: :internal_server_error, json: { message: 'Unknown error' }
  end
end
