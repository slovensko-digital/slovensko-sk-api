# TODO
# natural_person.pco

json.type { json.partial! 'enumeration', value: natural_person.identity_type_detail }

json.partial! 'natural_person_name', natural_person: natural_person.person_name
json.alternative_names natural_person.alternative_name

json.gender { json.partial! 'enumeration', value: natural_person.sex }

json.marital_status natural_person.marital_status
json.vital_status { json.partial! 'enumeration', value: natural_person.death&.status }

json.nationality { json.partial! 'enumeration', value: natural_person.nationality }
json.occupation { json.partial! 'enumeration', value: natural_person.occupation }

# TODO
# json.bank_connections natural_person.bank_connection do |c|
# end

# TODO
# json.related_persons natural_person.related_person do |c|
# end

json.birth do
  if natural_person.birth
    json.date natural_person.birth.date_of_birth.to_s.in_time_zone.to_date
    json.country { json.partial! 'enumeration', value: natural_person.birth.country }
    json.district { json.partial! 'enumeration', value: natural_person.birth.county }
    json.municipality { json.partial! 'enumeration', value: natural_person.birth.municipality }
    json.part natural_person.birth.district
  else
    json.nil!
  end
end

json.death do
  if natural_person.death
    json.date natural_person.death.date_of_death.to_s.in_time_zone.to_date
    json.country { json.partial! 'enumeration', value: natural_person.death.country }
    json.district { json.partial! 'enumeration', value: natural_person.death.county }
    json.municipality { json.partial! 'enumeration', value: natural_person.death.municipality }
    json.part natural_person.death.district
  else
    json.nil!
  end
end

json.updated_on natural_person.death&.date_of_status_change.to_s.to_date
