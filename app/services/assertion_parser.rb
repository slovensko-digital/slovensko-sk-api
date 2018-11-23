class AssertionParser
  def parse(response)
    document = response.decrypted_document || response.document
    assertion = REXML::XPath.first(document, '//saml:Assertion')

    # force namespaces directly on element, otherwise they are not present
    assertion.namespaces.slice('dsig', 'saml', 'xsi').each do |prefix, uri|
      assertion.add_namespace(prefix, uri)
    end

    # force double quotes on attributes, actually preserve response format
    assertion.context[:attribute_quote] = :quote

    assertion
  end
end
