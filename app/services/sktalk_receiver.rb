class SktalkReceiver
  def initialize(proxy)
    @upvs = proxy
  end

  def receive(message)
    message = SktalkMessages.from_xml(message)

    @upvs.sktalk.receive(message)
  end

  def save_to_outbox(message)
    message = SktalkMessages.from_xml(message)

    info = message.header.message_info
    info.clazz = 'EDESK_SAVE_APPLICATION_TO_OUTBOX'

    @upvs.sktalk.receive(message)
  end
end
