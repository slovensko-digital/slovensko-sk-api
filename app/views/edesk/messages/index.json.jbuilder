json.array! @messages do |message|
  json.id message.id_message
  json.class message.clazz.value
  json.message_id message.message_id.value
  json.correlation_id message.correlation_id.value
  json.subject message.title.value
  json.delivered_at EdeskMessageParser.parse_delivery_time(message.date_delivery)
end
