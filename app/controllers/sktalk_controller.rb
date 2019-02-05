class SktalkController < ApiController
  before_action { render_bad_request(:no_message) if params[:message].blank? }

  rescue_from(javax.xml.bind.UnmarshalException) { render_bad_request(:malformed_message) }

  def receive
    assertion = authenticate(scope: 'sktalk/receive')
    receive_result = receiver(assertion).receive(params[:message])

    render status: :ok, json: { receive_result: receive_result }
  end

  def receive_and_save_to_outbox
    assertion = authenticate(scope: 'sktalk/receive_and_save_to_outbox')
    receive_result = receiver(assertion).receive(params[:message])
    save_to_outbox_result = receiver(assertion).save_to_outbox(params[:message])

    render json: { receive_result: receive_result, save_to_outbox_result: save_to_outbox_result }
  end

  private

  def receiver(assertion)
    # TODO rm: cache it at least on UpvsEnvironment#upvs_proxy level
    @receiver ||= UpvsEnvironment.sktalk_receiver(assertion: assertion)
  end
end
