json.ids identity.general_data.egov_identifier do |egov_identifier|
  json.type sector = egov_identifier.sector_identifier.downcase
  json.value egov_identifier.identifier.tap { |id| id.downcase! if sector == 'sector_upvs' }
end

json.uri identity.general_data.uri
json.en identity.upvs_attributes.edesk_number
json.type identity.general_data.identity_type.value.downcase
json.status identity.upvs_attributes.identity_status.value.downcase
json.name identity.general_data.formatted_name
json.suffix identity.general_data.suffix

json.various_ids identity.id do |id|
  json.type { json.partial! 'enumeration', value: id.identifier_type }
  json.value id.identifier_value
  json.specified id.is_specified
end

json.upvs do
  json.edesk_number identity.upvs_attributes.edesk_number
  json.edesk_status identity.upvs_attributes.edesk_status&.value&.downcase
  json.edesk_remote_uri identity.upvs_attributes.edesk_remote_uri
  json.edesk_cuet_delivery_enabled identity.upvs_attributes.is_edesk_cuet_enabled
  json.edesk_delivery_limited identity.upvs_attributes.is_edesk_delivery_limited

  json.enotify_preferred_channel identity.upvs_attributes.enotify_preferred_channel&.value&.downcase
  json.enotify_preferred_calendar identity.upvs_attributes.enotify_preferred_calendar&.downcase
  json.enotify_emergency_allowed identity.upvs_attributes.is_enotify_emergency_allowed
  json.enotify_email_allowed identity.upvs_attributes.is_enotify_email_allowed
  json.enotify_sms_allowed identity.upvs_attributes.is_enotify_sms_allowed

  # TODO
  # identity.upvs_attributes.organizacna_zlozka_ovm
  # identity.upvs_attributes.issuer_foreign_eid
  # identity.upvs_attributes.location
  # identity.upvs_attributes.location_activated

  json.preferred_language identity.upvs_attributes.preferred_language&.value&.downcase

  json.re_iam_identity_id identity.upvs_attributes.re_identity_id
end

if identity.corporate_body
  json.corporate_body { json.partial! 'corporate_body', identity: identity, corporate_body: identity.corporate_body }
end

if identity.physical_person
  json.natural_person { json.partial! 'natural_person', identity: identity, natural_person: identity.physical_person }
end

json.addresses identity.physical_address do |a|
  raise 'Too many regions' if a.region.count > 1

  json.type a.type.value.underscore.remove('_address').tap { |t| t.replace('resident') if t == 'street' }
  json.inline a.address_line

  json.country { json.partial! 'enumeration', value: a.country }
  json.region a.region.first
  json.district { json.partial! 'enumeration', value: a.county }
  json.municipality { json.partial! 'enumeration', value: a.municipality }
  json.part a.district
  json.street a.street_name
  json.building_number a.building_number
  json.registration_number a.property_registration_number
  json.unit a.unit

  # TODO
  # json.address_point do
  # end

  json.building_index a.building_index

  json.delivery_address do
    if a.delivery_address
      json.(a.delivery_address, :postal_code, :post_office_box)

      json.recipient do
        if a.delivery_address.recipient
          if a.delivery_address.recipient.organization_unit || a.delivery_address.recipient.corporate_body_name
            json.corporate_body do
              json.organization_unit a.delivery_address.recipient.organization_unit
              json.partial! 'corporate_body_name', corporate_body: a.delivery_address.recipient
            end
          end

          if a.delivery_address.recipient.person_name
            json.natural_person do
              json.partial! 'natural_person_name', natural_person: a.delivery_address.recipient.person_name
            end
          end

          json.note a.delivery_address.recipient.additional_text
        else
          json.nil!
        end
      end
    else
      json.nil!
    end
  end

  json.ra_entry a.address_register_entry
  json.specified a.is_specified
end

json.emails identity.internet_address do |e|
  json.(e, :address, :dsig_key_info)
end

json.phones identity.telephone_address do |p|
  json.type { json.partial! 'enumeration', value: p.telephone_type }
  json.number p.telephone_number.formatted_number&.value
  json.(p.telephone_number, :international_country_code, :national_number, :area_city_code, :subscriber_number, :extension)
end
