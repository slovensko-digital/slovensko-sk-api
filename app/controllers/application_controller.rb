class ApplicationController < ActionController::API
  private

  def render_bad_request(message)
    render status: :bad_request, json: { message: message }
  end

  def render_unauthorized
    self.headers['WWW-Authenticate'] = 'Token realm="Slovensko.Digital API"'
    render status: :unauthorized, json: { message: 'Bad credentials' }
  end

  def render_timeout
    render status: :request_timeout, json: { message: 'Operation timeout exceeded' }
  end

  def render_payload_too_large
    render status: :request_timeout, json: { message: 'Message size limit exceeded' }
  end

  def render_too_many_requests
    render status: :too_many_requests, json: { message: 'Request rate limit exceeded' }
  end

  def render_internal_server_error
    render status: :internal_server_error, json: { message: 'Unknown error' }
  end
end
