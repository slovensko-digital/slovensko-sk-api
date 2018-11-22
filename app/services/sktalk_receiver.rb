class SktalkReceiver
  def initialize(proxy)
    @proxy = proxy
  end

  def receive(message)
    message = SktalkMessages.from_xml(message)

    @proxy.sktalk.receive(message)
  end
end
