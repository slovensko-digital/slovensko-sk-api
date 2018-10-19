package digital.slovensko.upvs;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import sk.gov.egov.iservice.IService;
import sk.gov.sktalkmessage.SKTalkMessage;

@Component
public final class Sktalk {
  @Autowired
  private IService service;

  private Sktalk() {}

  public int receive(final SKTalkMessage message) {
    return this.service.receive(message);
  }
}
