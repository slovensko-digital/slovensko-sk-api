package digital.slovensko.upvs;

import java.io.StringReader;
import java.io.StringWriter;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;
import javax.xml.bind.Unmarshaller;
import javax.xml.namespace.QName;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMResult;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import sk.gov.sktalkmessage.SKTalkMessage;

import static javax.xml.bind.Marshaller.JAXB_FORMATTED_OUTPUT;
import static javax.xml.bind.Marshaller.JAXB_FRAGMENT;
import static javax.xml.transform.OutputKeys.INDENT;
import static javax.xml.transform.OutputKeys.OMIT_XML_DECLARATION;

public final class SktalkMessages {
  private static final String INDENT_AMOUNT = "{http://xml.apache.org/xslt}indent-amount";

  private SktalkMessages() {}

  public static SKTalkMessage copyOf(final Object message) throws JAXBException, TransformerException {
    if (message instanceof SKTalkMessage) {
      return fromXml(toXml((SKTalkMessage) message));
    } else if (message instanceof CharSequence) {
      return fromXml(message.toString());
    }

    throw new IllegalArgumentException();
  }

  public static SKTalkMessage valueOf(final Object message) throws JAXBException, TransformerException {
    if (message instanceof SKTalkMessage) {
      return (SKTalkMessage) message;
    }

    return copyOf(message);
  }

  public static SKTalkMessage fromXml(final String content) throws JAXBException {
    JAXBContext context = JAXBContext.newInstance(SKTalkMessage.class);
    Unmarshaller unmarshaller = context.createUnmarshaller();

    StringReader reader = new StringReader(content);
    StreamSource source = new StreamSource(reader);

    JAXBElement<SKTalkMessage> element = unmarshaller.unmarshal(source, SKTalkMessage.class);
    SKTalkMessage message = element.getValue();

    return message;
  }

  public static String toXml(final SKTalkMessage message) throws JAXBException, TransformerException {
    JAXBContext context = JAXBContext.newInstance(SKTalkMessage.class);
    Marshaller marshaller = context.createMarshaller();

    marshaller.setProperty(JAXB_FRAGMENT, true);
    marshaller.setProperty(JAXB_FORMATTED_OUTPUT, true);

    QName name = new QName("http://gov.sk/eGov/IService", "SKTalkMessage");
    JAXBElement<SKTalkMessage> element = new JAXBElement<>(name, SKTalkMessage.class, message);

    DOMResult result = new DOMResult();
    StringWriter writer = new StringWriter();

    marshaller.marshal(element, result);

    Transformer transformer = TransformerFactory.newInstance().newTransformer();
    transformer.setOutputProperty(INDENT, "yes");
    transformer.setOutputProperty(OMIT_XML_DECLARATION, "yes");
    transformer.setOutputProperty(INDENT_AMOUNT, "2");
    transformer.transform(new DOMSource(result.getNode()), new StreamResult(writer));

    String content = writer.getBuffer().toString();
    content = content.replaceFirst("\\A<ns2:SKTalkMessage xmlns:ns2=\"http://gov.sk/eGov/IService\" xmlns=\"http://gov.sk/SKTalkMessage\">", "<SKTalkMessage xmlns=\"http://gov.sk/SKTalkMessage\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">");
    content = content.replaceFirst("</ns2:SKTalkMessage>\\Z", "</SKTalkMessage>");

    return content;
  }
}
