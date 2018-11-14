package digital.slovensko.upvs;

import java.util.LinkedHashMap;
import java.util.Map;

import digital.slovensko.upvs.client.EzClient;
import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.PropertySource;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;

import sk.gov.egov.iservice.IService;
import sk.gov.schemas.edesk.eksservice._1.IEKSService;
import sk.gov.schemas.identity.service._1_7.IdentityServices;

import digital.slovensko.upvs.log.PropertyResolver;

public final class UpvsProxy {
  private final ApplicationContext context;
  private final IEKSService eks;
  private final IdentityServices iam;
  private final IService sktalk;
  private final EzClient ezClient;

  public UpvsProxy(final Map<String, String> properties) {
    this.context = new Context(new MapPropertySource("upvs", new LinkedHashMap<>(properties)));

    this.eks = this.context.getBean(IEKSService.class);
    this.iam = this.context.getBean(IdentityServices.class);
    this.sktalk = this.context.getBean(IService.class);
    this.ezClient = this.context.getBean(EzClient.class);

    PropertyResolver.load(properties); // TODO remove
  }

  private static final class Context extends ClassPathXmlApplicationContext {
    Context(final PropertySource<?> source) {
      super(new String[] { "context.xml" }, false);

      this.getEnvironment().getPropertySources().addFirst(source);
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

  public IdentityServices getIam() {
    return this.iam;
  }

  public IService getSktalk() {
    return this.sktalk;
  }

  public EzClient getEzClient() {
    return this.ezClient;
  }
}
