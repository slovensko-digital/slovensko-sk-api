return json.nil! unless affix

json.type affix.type.underscore.remove('_title').tap { |t| t.replace('military') if t == 'form_of_address' }
json.value affix.value
