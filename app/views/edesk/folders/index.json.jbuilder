json.array! @folders do |folder|
  json.id folder.id_folder
  json.parent_id folder.id_folder_parent.value
  json.name folder.name.value
  json.system folder.is_system_folder
end
