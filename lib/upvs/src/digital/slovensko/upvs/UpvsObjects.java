package digital.slovensko.upvs;

import java.util.ArrayList;
import java.util.Collection;
import java.util.GregorianCalendar;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.xml.bind.JAXBElement;
import javax.xml.bind.annotation.XmlType;
import javax.xml.datatype.XMLGregorianCalendar;

import org.springframework.cglib.beans.BeanMap;

public final class UpvsObjects {
  private UpvsObjects() {}

  public static Object toStructure(final Object object) {
    if (object == null) {
      return null;
    } else if (object instanceof Enum) {
      return ((Enum<?>) object).name();
    } else if (object instanceof Collection) {
      return ((Collection<?>) object).stream().collect(ArrayList::new, (c, e) -> c.add(toStructure(e)), List::addAll);
    } else if (object instanceof Map) {
      return ((Map<?, ?>) object).entrySet().stream().collect(LinkedHashMap::new, (m, e) -> m.put(toStructure(e.getKey()), toStructure(e.getValue())), Map::putAll);
    } else if (object instanceof JAXBElement) {
      return toStructure(((JAXBElement<?>) object).getValue());
    } else if (object instanceof GregorianCalendar) {
      return ((GregorianCalendar) object).toZonedDateTime().toString();
    } else if (object instanceof XMLGregorianCalendar) {
      return ((XMLGregorianCalendar) object).toGregorianCalendar().toZonedDateTime().toString();
    } else if (object.getClass().isAnnotationPresent(XmlType.class)) {
      return toStructure(BeanMap.create(object));
    } else {
      return object;
    }
  }
}
