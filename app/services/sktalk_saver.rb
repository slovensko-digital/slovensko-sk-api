class SktalkSaver
  def initialize(receiver)
    @receiver = receiver
  end

  def save_to_outbox(message)
    message = SktalkMessages.from_xml(message)

    info = message.header.message_info
    info.clazz = 'EDESK_SAVE_APPLICATION_TO_OUTBOX'

    message = SktalkMessages.to_xml(message)

    @receiver.receive(message)
  end
end
