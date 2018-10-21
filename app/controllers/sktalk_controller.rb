class SktalkController < ApplicationController
  def receive
    render_bad_request('No credentials') and return unless params[:key].present?
    render_bad_request('No message') and return unless params[:message].present?

    result = service.receive(params[:message])

    render status: :ok, json: { result: result }
  rescue SafeTimeoutError
    render_timeout
  rescue
    render_internal_server_error
  end

  private

  def service
    UpvsEnvironment.sktalk_service(params[:key])
  end

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
