// TODO remove this after removing appropriate configuration files

package digital.slovensko.upvs.internals;

import java.io.StringReader;

import javax.xml.stream.XMLStreamException;

import org.apache.cxf.staxutils.StaxUtils;
import org.springframework.core.convert.converter.Converter;
import org.springframework.stereotype.Component;
import org.w3c.dom.Element;

@Component
public class StringToElementConverter implements Converter<String, Element> {
  @Override
  public Element convert(final String value) {
    try {
      return StaxUtils.read(new StringReader(value)).getDocumentElement();
    } catch (XMLStreamException e) {
      throw new RuntimeException(e);
    }
  }
}
