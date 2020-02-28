class SktalkController < ApiController
  before_action { render_bad_request(:no_message) if params[:message].blank? }

  rescue_from(SktalkReceiver::ReceiveMessageFormatError) { render_bad_request(:malformed_message) }
  rescue_from(SktalkReceiver::ReceiveAsSaveToOutboxError) { render_bad_request(:unsupported_message) }

  def receive
    assertion = assertion('sktalk/receive')

    render json: receiver(assertion).receive(params[:message], save_to_outbox: false).to_h.compact
  end

  def receive_and_save_to_outbox
    assertion = assertion('sktalk/receive_and_save_to_outbox')

    render json: receiver(assertion).receive(params[:message], save_to_outbox: true)
  end

  private

  def assertion(scope)
    authenticate(allow_ta: true, allow_obo: true, require_obo_scope: scope)
  end

  def receiver(assertion)
    UpvsEnvironment.sktalk_receiver(assertion: assertion)
  end
end
