# TODO validate form version status in #before_action
# TODO validate input message against XSD in #before_action

class SktalkController < ApiController
  include SktalkReceiving

  before_action { authenticate(allow_sub: true, allow_obo_token: true, require_obo_token_scope: action_scope) }

  before_action { params.require(:message) }

  rescue_from(SktalkReceiver::ReceiveMessageFormatError) { render_bad_request(:invalid, :message) }
  rescue_from(SktalkReceiver::ReceiveAsSaveToFolderError) { render_unprocessable_entity(:received_as_being_saved_to_folder) }

  def receive
    render json: { receive_result: sktalk_receiver(upvs_identity).receive(params[:message]) }
  end

  def receive_and_save_to_outbox
    render_sktalk_results sktalk_receiver(upvs_identity).receive_and_save_to_outbox!(params[:message])
  end

  def save_to_outbox
    render json: { save_to_outbox_result: sktalk_receiver(upvs_identity).save_to_outbox(params[:message]) }
  end
end
