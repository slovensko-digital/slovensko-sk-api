// TODO remove this after removing appropriate configuration files

package digital.slovensko.upvs.internals;

import java.net.URL;
import java.util.Map;
import java.util.logging.ConsoleHandler;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.LogManager;
import java.util.logging.Logger;

import ch.qos.logback.classic.LoggerContext;
import ch.qos.logback.classic.joran.JoranConfigurator;
import ch.qos.logback.classic.util.ContextInitializer;
import ch.qos.logback.core.PropertyDefinerBase;
import ch.qos.logback.core.joran.spi.JoranException;
import org.slf4j.LoggerFactory;

import static java.util.Collections.emptyMap;

import static com.google.common.collect.ImmutableMap.copyOf;

public final class LoggerPropertyDefiner extends PropertyDefinerBase {
  private static Map<String, Object> properties = emptyMap();

  private String propertyKey;

  private String propertyDefault;

  public LoggerPropertyDefiner() {}

  public static void load(final Map<String, Object> properties) {
    synchronized (LoggerPropertyDefiner.class) {
      LoggerPropertyDefiner.properties = copyOf(properties);

      reconfigureLogbackLoggerContext();
      reconfigureJavaLoggingLevelOnConsoleHandlers();
    }
  }

  private static void reconfigureLogbackLoggerContext() {
    LoggerContext context = (LoggerContext) LoggerFactory.getILoggerFactory();
    ContextInitializer initializer = new ContextInitializer(context);
    URL url = initializer.findURLOfDefaultConfigurationFile(true);

    context.reset();

    try {
      JoranConfigurator configurator = new JoranConfigurator();

      configurator.setContext(context);
      configurator.doConfigure(url);
    } catch (JoranException e) {
      throw new RuntimeException(e);
    }
  }

  private static void reconfigureJavaLoggingLevelOnConsoleHandlers() {
    Level level = Level.parse(properties.getOrDefault("upvs.log.java.console.level", "OFF").toString());
    Logger logger = LogManager.getLogManager().getLogger("");

    for (Handler handler: logger.getHandlers()) {
      if (handler instanceof ConsoleHandler) {
        handler.setLevel(level);
      }
    }
  }

  public void setPropertyKey(final String key) {
    this.propertyKey = key;
  }

  public void setPropertyDefault(final String value) {
    this.propertyDefault = value;
  }

  public String getPropertyValue() {
    return properties.getOrDefault(this.propertyKey, this.propertyDefault).toString();
  }
}
