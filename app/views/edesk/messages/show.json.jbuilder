# set class two times because setting it the first time marks its position
json.(@message, :id, :class, :message_id, :correlation_id, :reference_id, :posp_id, :posp_version, :sender_uri, :recipient_uri, :type, :subject, :sender_business_reference, :recipient_business_reference, :objects, :original_html, :original_xml)
json.class @message.klass
json.delivered_at @message.delivered_at

json.objects @message.objects do |o|
  json.(o, :id, :name, :description, :class, :signed, :mime_type, :encoding, :content)
  json.class o.klass
end

if @message.delivery_notification
  json.delivery_notification do
    json.authorize_url authorize_edesk_message_url(@message.id)

    json.consignment do
      json.(@message.delivery_notification.consignment, :message_id, :message_type, :message_subject, :attachments, :note)

      json.attachments @message.delivery_notification.consignment.attachments do |a|
        json.(a, :id, :name)
      end
    end

    json.delivery_period @message.delivery_notification.delivery_period
    json.delivery_period_end_at @message.delivery_notification.delivery_period_end_at
    json.received_at @message.delivery_notification.received_at
  end
end

json.parse_error @message.parse_error.present?
