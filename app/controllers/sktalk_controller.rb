class SktalkController < ApiController
  before_action { render_bad_request(:no_message) if params[:message].blank? }

  rescue_from(SktalkReceiver::ReceiveMessageFormatError) { render_bad_request(:malformed_message) }
  rescue_from(SktalkReceiver::ReceiveAsSaveToOutboxError) { render_bad_request(:unsupported_message) }

  def receive
    assertion = assertion('sktalk/receive')

    render json: { receive_result: receiver(assertion).receive(params[:message]) }
  end

  def receive_and_save_to_outbox
    assertion = assertion('sktalk/receive_and_save_to_outbox')

    results = receiver(assertion).receive_and_save_to_outbox!(params[:message])
    status = results.receive_timeout || results.save_to_outbox_timeout ? :request_timeout : :ok

    render status: status, json: results
  end

  def save_to_outbox
    assertion = assertion('sktalk/save_to_outbox')

    render json: { save_to_outbox_result: receiver(assertion).save_to_outbox(params[:message]) }
  end

  private

  def assertion(scope)
    authenticate(allow_ta: true, allow_obo: true, require_obo_scope: scope)
  end

  def receiver(assertion)
    UpvsEnvironment.sktalk_receiver(assertion: assertion)
  end
end
