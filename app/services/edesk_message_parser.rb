class EdeskMessageParser
  ParseError = Class.new(RuntimeError)

  def parse(edesk_message)
    m = Message.new

    m.id = edesk_message.id_message
    m.klass = edesk_message.clazz.value
    m.message_id = edesk_message.message_id.value
    m.correlation_id = edesk_message.correlation_id.value
    m.subject = edesk_message.title.value
    m.original_html = self.class.parse_original_html(edesk_message.body.value)
    m.original_xml = edesk_message.sk_talk.value
    m.delivered_at = self.class.parse_delivery_time(edesk_message.date_delivery)

    begin
      build_message(m)
    rescue ParseError => e
      m.parse_error = e
    end

    m
  end

  def self.parse_delivery_time(s)
    offset = Time.use_zone('Europe/Bratislava') { Time.zone.parse(s.to_s).strftime('%:z') }
    Time.zone.parse(s.to_s + offset)
  end

  def self.parse_original_html(s)
    HTMLEntities.new(:expanded).decode(s)
  end

  private

  def build_message(m)
    d = Nokogiri::XML.parse(m.original_xml) { |config| config.noblanks }

    build_message_from_sktalk_message(d, m)
  end

  def build_message_from_sktalk_message(d, m)
    raise ParseError if d.children.count != 1

    d = d.children.first

    raise ParseError if d.name != 'SKTalkMessage'

    d.children.each do |e|
      case e.name
      when 'EnvelopeVersion'
        raise ParseError if e.content != '3.0'
      when 'Header'
        build_message_from_header(e, m)
      when 'Body'
        build_message_from_body(e, m)
      else
        raise ParseError
      end
    end
  end

  def build_message_from_header(d, m)
    d.children.each do |e|
      case e.name
      when 'MessageInfo'
        build_message_from_message_info(e, m)
      when 'SenderInfo'
        # skip
      else
        raise ParseError
      end
    end
  end

  def build_message_from_message_info(d, m)
    d.children.each do |e|
      case e.name
      when 'Class'
        raise ParseError if e.content != m.klass
      when 'PospID'
        m.posp_id = e.content.presence
      when 'PospVersion'
        m.posp_version = e.content.presence
      when 'MessageID'
        raise ParseError if e.content != m.message_id
      when 'CorrelationID'
        raise ParseError if e.content != m.correlation_id
      when 'ReferenceID'
        m.reference_id = e.content.presence
      when 'BusinessID'
        # skip
      when 'ChannelInfo', 'ChannelInfoReply'
        # skip
      else
        raise ParseError
      end
    end
  end

  def build_message_from_body(d, m)
    raise ParseError if d.children.count > 1

    d.children.each do |e|
      case e.name
      when 'MessageContainer'
        build_message_from_message_container(e, m)
      when 'InformationMessage'
        # skip
      else
        raise ParseError
      end
    end
  end

  def build_message_from_message_container(d, m)
    d.children.each do |e|
      case e.name
      when 'MessageId'
        raise ParseError if e.content != m.message_id
      when 'SenderId'
        m.sender_uri = e.content
      when 'RecipientId'
        m.recipient_uri = e.content
      when 'MessageType'
        m.type = e.content
      when 'MessageSubject'
        raise ParseError if e.content != m.subject
      when 'SenderBusinessReference'
        m.sender_business_reference = e.content.presence
      when 'RecipientBusinessReference'
        m.recipient_business_reference = e.content.presence
      when 'Object'
        build_message_object_from_object(e, m)
      else
        raise ParseError
      end
    end
  end

  def build_message_object_from_object(d, m)
    m.objects << o = Message::Object.new

    d.attributes.each do |name, attribute|
      value = attribute.value

      case name
      when 'Id'
        o.id = value
      when 'Class'
        o.klass = value
      when 'Name'
        o.name = value.presence
      when 'Description'
        o.description = value.presence
      when 'Encoding'
        o.encoding = value
      when 'MimeType'
        o.mime_type = value
      when 'IsSigned'
        o.signed = value.casecmp?('true')
      else
        raise ParseError
      end
    end

    o.content = d.children.to_s

    if m.klass == 'ED_DELIVERY_NOTIFICATION'
      raise ParseError if d.children.count > 1 || d.children.first.name != 'DeliveryReportNotification'
      build_message_delivery_notification_from_delivery_report_notification(d.children.first, m)
    end
  end

  def build_message_delivery_notification_from_delivery_report_notification(d, m)
    m.delivery_notification = n = Message::DeliveryNotification.new

    d.children.each do |e|
      case e.name
      when 'Persons'
        # skip
      when 'DeliveryInformation'
        build_delivery_notification_from_delivery_information(e, n)
      when 'Consignment'
        build_delivery_notification_consignment_from_consignment(e, n)
      else
        raise ParseError
      end
    end
  end

  def build_delivery_notification_from_delivery_information(d, n)
    d.children.each do |e|
      case e.name
      when 'Received'
        n.received_at = e.content.in_time_zone if e.content.present?
      when 'DeliveryPeriod'
        n.delivery_period = Integer(e.content, 10) if e.content.present?
      when 'DeliveryPeriodEnd'
        n.delivery_period_end_at = e.content.in_time_zone if e.content.present?
      else
        raise ParseError
      end
    end
  end

  def build_delivery_notification_consignment_from_consignment(d, n)
    n.consignment = c = Message::DeliveryNotification::Consignment.new

    d.children.each do |e|
      case e.name
      when 'MessageID'
        c.message_id = e.content
      when 'MessageSubject'
        c.message_subject = e.content
      when 'MessageType'
        c.message_type = e.content
      when 'Note'
        c.note = e.content
      when 'Attachments'
        e.children.each do |a|
          build_consignment_attachment_from_attachment(a, c)
        end
      else
        raise ParseError
      end
    end
  end

  def build_consignment_attachment_from_attachment(d, c)
    c.attachments << a = Message::DeliveryNotification::Consignment::Attachment.new

    d.children.each do |e|
      case e.name
      when 'AttachmentId'
        a.id = e.content
      when 'AttachmentName'
        a.name = e.content
      else
        raise ParseError
      end
    end
  end
end
