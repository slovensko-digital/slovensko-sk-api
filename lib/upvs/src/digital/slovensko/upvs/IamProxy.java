package digital.slovensko.upvs;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import sk.gov.schemas.identity.service._1_7.IdentityServices;

@Component
public final class IamProxy {
  @Autowired
  private IdentityServices service;

  private IamProxy() {}
}
