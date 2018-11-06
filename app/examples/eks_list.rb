require_relative '../../config/environment'

eks = UpvsEnvironment.upvs_proxy(nil).eks

# TODO add helper to hide the #values.value.folder chain
# TODO add ArrayOfFolder conversion in Java #to_structure to convert ['values']['folder'] to just ['values']
# (note that #to_structure already converts JAXBElement so ['values']['value']['folder'] becomes ['values']['folder'])

response = eks.get_folders
folders = response.values.value.folder

folders.each do |folder|
  response = eks.get_messages(folder.id_folder, 1_000_000, 0)
  messages = response.values.value.message
  count = response.total_count

  puts "#{folder.id_folder} #{folder.name.value} - #{count} #{'message'.pluralize(count)}"

  messages.each do |message|
    time = DateTime.parse(message.date_delivery.to_s)

    puts "  #{time.strftime('%F %T')} #{message.id_message} #{message.clazz.value} - #{message.title.value}"
  end

  # TODO rm
  # puts UpvsObjects.to_structure(folder)
  # puts UpvsObjects.to_structure(messages)
end
