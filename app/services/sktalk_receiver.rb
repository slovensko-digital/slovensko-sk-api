# TODO try to force timeout via http://cxf.apache.org/docs/client-http-transport-including-ssl-support.html#ClientHTTPTransport(includingSSLsupport)-Theclientelement

class SktalkReceiver
  include ForceTimeout
  include UnwrapErrors

  def initialize(proxy)
    @upvs = proxy
  end

  def receive(message)
    message = SktalkMessages.from_xml(message)
    timeout(60.seconds) { @upvs.sktalk.receive(message) }
  end
end
