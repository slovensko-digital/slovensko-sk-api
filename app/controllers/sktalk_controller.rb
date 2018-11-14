class SktalkController < ApplicationController
  def receive
    render_bad_request('No credentials') and return unless params[:key].present?
    render_bad_request('No message') and return unless params[:message].present?

    receiver = UpvsEnvironment.sktalk_receiver(params[:key])
    result = receiver.receive(params[:message])

    render status: :ok, json: { result: result }
  rescue

    # TODO check the whole full causal chain
    if $!.cause&.cause.is_a?(java.net.SocketTimeoutException)
      render_timeout
    else
      render_internal_server_error
    end
  end
end
