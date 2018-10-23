class SktalkService < UpvsService
  def receive(message, wait: 60.seconds)
    message = digital.slovensko.upvs.SktalkMessages::from_xml(message)
    timeout(wait) { upvs.sktalk.receive(message) }
  end
end
