class SktalkReceiver
  def initialize(proxy)
    @upvs = proxy
  end

  ReceiveMessageFormatError = Class.new(ArgumentError)
  ReceiveAsSaveToFolderError = Class.new(ArgumentError)

  ReceiveAndSaveToOutboxResults = Struct.new(:receive_result, :receive_timeout, :save_to_outbox_result, :save_to_outbox_timeout, keyword_init: true)

  def receive(message)
    object = parse(message)
    @upvs.sktalk.receive(object)
  end

  def receive_and_save_to_outbox!(message)
    object = parse(message)
    results = ReceiveAndSaveToOutboxResults.new

    begin
      results.receive_result = @upvs.sktalk.receive(object)
      results.receive_timeout = false
    rescue => error
      raise error unless timeout?(error)
      results.receive_timeout = true
    end

    if results.receive_result&.zero?
      object = parse(message)
      object.header.message_info.clazz = SAVE_TO_OUTBOX_CLASS

      begin
        results.save_to_outbox_result = @upvs.sktalk.receive(object)
        results.save_to_outbox_timeout = false
      rescue => error
        raise error unless timeout?(error)
        results.save_to_outbox_timeout = true
      end
    end

    results
  end

  def save_to_outbox(message)
    object = parse(message)
    object.header.message_info.clazz = SAVE_TO_OUTBOX_CLASS
    @upvs.sktalk.receive(object)
  end

  private

  SAVE_TO_DRAFTS_CLASS = 'EDESK_SAVE_APPLICATION_TO_DRAFTS'
  SAVE_TO_OUTBOX_CLASS = 'EDESK_SAVE_APPLICATION_TO_OUTBOX'

  def parse(message)
    object = SktalkMessages.from_xml(message)
    raise ReceiveAsSaveToFolderError if object.header.message_info.clazz.in?([SAVE_TO_DRAFTS_CLASS, SAVE_TO_OUTBOX_CLASS])
    object
  rescue javax.xml.bind.UnmarshalException
    raise ReceiveMessageFormatError
  end

  def timeout?(error)
    com.google.common.base.Throwables.get_causal_chain(error).any? { |e| e.message =~ /timed out/i }
  end

  private_constant :SAVE_TO_OUTBOX_CLASS
end
