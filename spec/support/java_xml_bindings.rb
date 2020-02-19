module JavaXmlBindings
  def java_object_from_xml(object_class, content)
    content = javax.xml.transform.stream.StreamSource.new(java.io.StringReader.new(content)) if content.is_a?(String)
    context = javax.xml.bind.JAXBContext.new_instance(object_class.java_class)
    context.create_unmarshaller.unmarshal(content, object_class.java_class).value
  end
end

RSpec.configure do |config|
  config.include JavaXmlBindings
end
