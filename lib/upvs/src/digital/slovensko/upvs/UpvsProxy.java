package digital.slovensko.upvs;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.PropertySource;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;

import sk.gov.egov.iservice.IService;
import sk.gov.schemas.edesk.eksservice._1.IEKSService;
import sk.gov.schemas.identity.service._1_7.IdentityServices;
import sk.gov.schemas.servicebus.service._1_0.IServiceBus;

import digital.slovensko.upvs.internals.LoggerPropertyDefiner;

import static com.google.common.collect.Lists.newArrayList;

public final class UpvsProxy {
  private final ApplicationContext context;

  private final IEKSService eks;

  private final IServiceBus ez;

  private final IdentityServices iam;

  private final IService sktalk;

  public UpvsProxy(final Map<String, Object> properties) {
    Map<String, Object> copy = new LinkedHashMap<>(properties);

    LoggerPropertyDefiner.load(copy);

    List<String> configurations = newArrayList("context.xml", "ws.xml");
    configurations.add(copy.containsKey("upvs.sts.obo") ? "ws-onbehalf.xml" : "ws-techcert.xml");

    this.context = new Context(configurations, new MapPropertySource("args", copy));

    this.eks = this.context.getBean(IEKSService.class);
    this.ez = this.context.getBean(IServiceBus.class);
    this.iam = this.context.getBean(IdentityServices.class);
    this.sktalk = this.context.getBean(IService.class);
  }

  private static final class Context extends ClassPathXmlApplicationContext {
    Context(final List<String> configurations, final PropertySource<?> properties) {
      super(configurations.toArray(new String[configurations.size()]), false);

      this.getEnvironment().getPropertySources().addFirst(properties);
      this.refresh();
    }

    @Override
    protected Resource getResourceByPath(final String path) {
      Resource resource = super.getResourceByPath(path);

      return resource.exists() ? resource : new FileSystemResource(path);
    }
  }

  public IEKSService getEks() {
    return this.eks;
  }

  public IServiceBus getEz() {
    return this.ez;
  }

  public IdentityServices getIam() {
    return this.iam;
  }

  public IService getSktalk() {
    return this.sktalk;
  }
}
