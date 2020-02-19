json.name natural_person.formatted_name
json.given_names natural_person.given_name
json.preferred_given_name natural_person.preferred_given_name

json.given_family_names natural_person.given_family_name do |n|
  json.primary n.is_primary
  json.(n, :prefix, :value)
end

json.family_names natural_person.family_name do |n|
  json.primary n.is_primary
  json.(n, :prefix, :value)
end

json.legal_name natural_person.legal_name
json.other_name natural_person.other_name

json.prefixes natural_person.affix.select { |a| a.position.to_s == 'Prefix' }, partial: 'affix'
json.suffixes natural_person.affix.select { |a| a.position.to_s == 'Postfix' }, partial: 'affix'
