class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # TODO fix https://guides.rubyonrails.org/action_controller_overview.html#rescue-from
  #rescue_from StandardError, with: :render_internal_server_error unless Rails.env.development?

  rescue_from JWT::DecodeError, with: :render_unauthorized

  private

  # TODO maybe render HTML error message here
  def render_unauthorized
    self.headers['WWW-Authenticate'] = 'Token realm="PODAAS"'
    render status: :unauthorized
  end

  # TODO maybe render HTML error message here
  def render_internal_server_error
    render status: :internal_server_error
  end
end
