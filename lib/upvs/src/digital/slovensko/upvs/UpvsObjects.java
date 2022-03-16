package digital.slovensko.upvs;

import java.io.StringReader;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.GregorianCalendar;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;
import javax.xml.bind.Unmarshaller;
import javax.xml.bind.annotation.XmlSchema;
import javax.xml.bind.annotation.XmlType;
import javax.xml.datatype.XMLGregorianCalendar;
import javax.xml.namespace.QName;

import org.springframework.cglib.beans.BeanMap;

public final class UpvsObjects {
  private static final JAXBContext JAXB_CONTEXT = newJaxbContext(
    org.datacontract.schemas._2004._07.anasoft_edesk.ObjectFactory.class,
    org.datacontract.schemas._2004._07.anasoft_edesk_edeskii.ObjectFactory.class,
    sk.gov.schemas.edesk.eksservice._1.ObjectFactory.class,
    sk.gov.schemas.edesk.eksservice._1.ObjectFactory.class,
    sk.gov.schemas.identity.identitydata._1.ObjectFactory.class,
    sk.gov.schemas.identity.service._1.ObjectFactory.class,
    sk.gov.schemas.servicebus.service._1.ObjectFactory.class,
    sk.gov.schemas.servicebusserviceprovider.ditec.cepprovider._1.ObjectFactory.class,
    sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.ObjectFactory.class
  );

  private UpvsObjects() {}

  private static JAXBContext newJaxbContext(final Class<?> ... classes) {
    try {
      return JAXBContext.newInstance(classes);
    } catch (JAXBException e) {
      throw new RuntimeException(e);
    }
  }

  public static Object fromXml(final String content) throws JAXBException {
    return fromXml(content, false);
  }

  // TODO this does not work with SKTalkMessage, try another data binding -> http://cxf.apache.org/docs/databindings.html
  public static Object fromXml(final String content, final boolean validate) throws JAXBException {
    Unmarshaller unmarshaller = JAXB_CONTEXT.createUnmarshaller();
    unmarshaller.setEventHandler(e -> { return !validate; });
    Object object = unmarshaller.unmarshal(new StringReader(content));
    return object instanceof JAXBElement ? ((JAXBElement<?>) object).getValue() :object;
  }

  // TODO this generates too many unused namespaces, try another data binding -> http://cxf.apache.org/docs/databindings.html
  public static String toXml(final Object object) throws JAXBException {
    Marshaller marshaller = JAXB_CONTEXT.createMarshaller();
    @SuppressWarnings("unchecked")
    Class<Object> type = (Class<Object>) object.getClass();
    QName name = new QName(type.getPackage().getAnnotation(XmlSchema.class).namespace(), type.getAnnotation(XmlType.class).name());
    JAXBElement<?> element = new JAXBElement<>(name, type, object);
    StringWriter writer = new StringWriter();
    marshaller.marshal(element, writer);
    return writer.toString();
  }

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
      BeanMap.Generator gen = new BeanMap.Generator();
      gen.setBean(object);
      gen.setContextClass(object.getClass());
      return toStructure(gen.create());
    } else {
      return object;
    }
  }
}
