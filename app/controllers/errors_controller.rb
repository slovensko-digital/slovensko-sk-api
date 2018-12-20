class ErrorsController < ApiController
  def internal_server_error
    render_internal_server_error
  end
end
