class Message
  # set from eDesk response
  attr_accessor :id, :klass, :message_id, :correlation_id, :subject, :original_html, :original_xml, :delivered_at

  # set from SKTalk message
  attr_accessor :posp_id, :posp_version, :reference_id
  attr_accessor :sender_uri, :recipient_uri, :type, :sender_business_reference, :recipient_business_reference, :objects

  # set specially
  attr_accessor :delivery_notification

  # set internally
  attr_accessor :parse_error

  def initialize
    @objects = []
  end

  class Object
    attr_accessor :id, :name, :description, :klass, :signed, :mime_type, :encoding, :content
  end

  class DeliveryNotification
    # set from consignment
    attr_accessor :consignment

    # set from delivery information
    attr_accessor :delivery_period, :delivery_period_end_at, :received_at

    class Consignment
      attr_accessor :message_id, :message_type, :message_subject, :attachments, :note

      def initialize
        @attachments = []
      end

      class Attachment
        attr_accessor :id, :name
      end
    end
  end
end
