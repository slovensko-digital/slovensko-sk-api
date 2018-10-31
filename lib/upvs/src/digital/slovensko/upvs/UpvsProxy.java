package digital.slovensko.upvs;

import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.PropertySource;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;

import digital.slovensko.upvs.log.PropertyResolver;

public final class UpvsProxy {
  private final ApplicationContext context;

  private final SktalkProxy sktalk;

  public UpvsProxy(final Map<String, String> properties) {
    this.context = new Context(new MapPropertySource("upvs", new LinkedHashMap<>(properties)));

    this.sktalk = this.context.getBean(SktalkProxy.class);

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

  public SktalkProxy getSktalkProxy() {
    return this.sktalk;
  }
}
