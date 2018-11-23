class SktalkController < ApiController
  before_action { render_bad_request('No credentials') if params[:token].blank? }
  before_action { render_bad_request('No message') if params[:message].blank? }

  def receive
    assertion = authenticator.verify_token(params[:token])
    receive_result = receiver(assertion).receive(params[:message])

    render status: :ok, json: { receive_result: receive_result }
  end

  def receive_and_save_to_outbox
    assertion = authenticator.verify_token(params[:token])
    receive_result = receiver(assertion).receive(params[:message])
    save_to_outbox_result = receiver(assertion).save_to_outbox(params[:message])

    render json: { receive_result: receive_result, save_to_outbox_result: save_to_outbox_result }
  end

  private

  def receiver(assertion)
    UpvsEnvironment.sktalk_receiver(assertion)
  end
end
