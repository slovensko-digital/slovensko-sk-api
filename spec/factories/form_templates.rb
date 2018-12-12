FactoryBot.define do
  factory :form_template do
    identifier { "App.GeneralAgenda" }
    version_major { 1 }
    version_minor { 9 }
  end

  factory :form_template_related_document do
    form_template
    language { 'sk' }
    document_type { 'CLS_F_XSD_EDOC' }
    data { '<?xml version="1.0" encoding="UTF-8"?>' }

    trait :general_agenda_xsd_schema do
      association :form_template, identifier: 'App.GeneralAgenda', version_major: 1, version_minor: 7
      data do
        <<~HEREDOC
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema elementFormDefault="qualified" attributeFormDefault="unqualified" xmlns:xs="http://www.w3.org/2001/XMLSchema" targetNamespace="http://schemas.gov.sk/form/App.GeneralAgenda/1.7" xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.7">
          <xs:simpleType name="textArea">
            <xs:restriction base="xs:string"></xs:restriction>
          </xs:simpleType>
          <xs:simpleType name="meno">
            <xs:restriction base="xs:string"></xs:restriction>
          </xs:simpleType>
          
          <xs:element name="GeneralAgenda">
            <xs:complexType>
              <xs:sequence>
                <xs:element name="subject" type="meno" minOccurs="0" nillable="true" />
                <xs:element name="text" type="textArea" minOccurs="0" nillable="true" />
              </xs:sequence>
            </xs:complexType>
          </xs:element>
        </xs:schema>
        HEREDOC
      end
    end
  end
end
