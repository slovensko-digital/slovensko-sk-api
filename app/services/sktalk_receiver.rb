class SktalkReceiver
  def initialize(proxy)
    @upvs = proxy
  end

  ReceiveMessageFormatError = Class.new(ArgumentError)
  ReceiveAsSaveToOutboxError = Class.new(ArgumentError)

  ReceiveResults = Struct.new(:receive_result, :save_to_outbox_result)

  def receive(message, save_to_outbox:)
    message = SktalkMessages.from_xml(message)
    raise ReceiveAsSaveToOutboxError if message.header.message_info.clazz == SAVE_TO_OUTBOX_CLASS
    results = ReceiveResults.new(@upvs.sktalk.receive(message))

    if save_to_outbox && results.receive_result.zero?
      message.header.message_info.clazz = SAVE_TO_OUTBOX_CLASS
      results.save_to_outbox_result = @upvs.sktalk.receive(message)
    end

    results
  rescue javax.xml.bind.UnmarshalException
    raise ReceiveMessageFormatError
  end

  private

  SAVE_TO_OUTBOX_CLASS = 'EDESK_SAVE_APPLICATION_TO_OUTBOX'

  private_constant :SAVE_TO_OUTBOX_CLASS
end
