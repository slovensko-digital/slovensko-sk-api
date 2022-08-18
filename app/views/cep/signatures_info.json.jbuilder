json.is_signed @response.kod == 0
json.description @response.popis.value

if @response.kod == 0
  json.mime_type @response.mime_type.value

  json.signatures @response.podpisy.value.ztfp2_podpis.to_a.each do |signature|
    json.type signature.typ_podpisu.value
    json.format signature.format_podpisu.value
    json.with_timestamp signature.is_obsahuje_casovu_peciatku
  end
end
