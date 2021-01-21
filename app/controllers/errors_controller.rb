class ErrorsController < ApiController
  skip_before_action(:verify_request_body)
  skip_before_action(:verify_format)

  def internal_server_error
    render_internal_server_error
  end
end
