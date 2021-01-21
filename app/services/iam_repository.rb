class IamRepository
  def initialize(proxy)
    @upvs = proxy
  end

  def identity(id)
    request = factory.create_get_identity_request
    request.identity_id = id

    @upvs.iam.get_identity(request).identity_data
  end

  def search(match: 'exact', page: 1, per_page: 20, **identity)
    request = factory.create_get_edesk_info2_request
    request.search_type = SearchType.from_value(MATCHES.fetch(match)) if match
    request.identity_request = new_identity_request(identity)
    request.paging = factory.create_paging_type
    request.paging.start_index = (page - 1) * per_page + 1
    request.paging.num_records_per_page = per_page

    @upvs.iam.get_edesk_info2(request).identity_data.to_a
  end

  private

  ADDRESS_TYPES = { 'contact' => 'CONTACTADDRESS', 'resident' => 'STREETADDRESS' }
  IDENTITY_TYPES = { 'natural_person' => 1, 'corporate_body' => 2, 'technical_account' => 3, 'employee_of_public_administration' => 5, 'institution_of_public_administration' => 6 }
  # CORPORATE_BODY_LEGAL_FORMS = {} # TODO
  # NATURAL_PERSON_TYPES = {} # TODO
  MATCHES = { 'exact' => 'EXACT', 'prefix' => 'BEGINWITH', 'infix' => 'INMIDDLE' }

  mattr_reader :factory, default: sk.gov.schemas.identity.service._1.ObjectFactory.new

  java_import sk.gov.schemas.identity.service._1.ERequestAddressType
  java_import sk.gov.schemas.identity.service._1.SearchType

  def new_identity_request(ids: [], uris: [], en: nil, type: nil, email: nil, phone: nil, address: {}, corporate_body: {}, natural_person: {})
    request = factory.create_identity_request2_type
    request.identity_id.add_all(ids + uris)
    request.edesk_number = en
    request.identity_type = IDENTITY_TYPES.fetch(type).to_s if type
    request.email = email
    request.telephone_number = phone
    request.physical_address = new_address(address) if address.present?
    request.corporate_body = new_corporate_body(corporate_body) if corporate_body.present?
    request.physical_person = new_natural_person(natural_person) if natural_person.present?
    request
  end

  def new_address(type: nil, country: nil, district: nil, municipality: nil, street: nil, building_number: nil, registration_number: nil)
    address = factory.create_physical_address_request2_type
    address.address_type = ERequestAddressType.from_value(ADDRESS_TYPES.fetch(type)) if type
    address.country = new_value(country) if country
    address.county = new_value(district) if district
    address.municipality = new_value(municipality) if municipality
    address.street = street
    address.building_number = building_number
    address.property_registration_number = registration_number
    address
  end

  def new_corporate_body(cin: nil, tin: nil, name: nil)
    corporate_body = factory.create_corporate_body_request_type
    corporate_body.company_registration_number = cin.to_s if cin
    corporate_body.vat_number = tin.to_s if tin
    corporate_body.corporate_body_name = name
    # corporate_body.legal_form = CORPORATE_BODY_LEGAL_FORMS.fetch(legal_form).to_s if type # TODO
    corporate_body
  end

  def new_natural_person(given_name: nil, family_name: nil, date_of_birth: nil, place_of_birth: nil)
    natural_person = factory.create_physical_person_request_type
    # natural_person.identity_type_detail = NATURAL_PERSON_TYPES.fetch(type).to_s if type # TODO
    natural_person.given_name = given_name
    natural_person.family_name = family_name
    natural_person.birth_date = UpvsObjects.datatype_factory.new_xml_gregorian_calendar(date_of_birth) if date_of_birth
    natural_person.birth_city = place_of_birth
    natural_person
  end

  def new_value(id: nil, name: nil)
    value = factory.create_lov_value
    value.id = id
    value.title_sk = name
    value
  end

  private_constant *constants(false)
end
