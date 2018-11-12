class SktalkReceiver
  include UnwrapErrors

  def initialize(proxy)
    @upvs = proxy
  end

  def receive(message)
    message = SktalkMessages.from_xml(message)
    @upvs.sktalk.receive(message)
  end
end
