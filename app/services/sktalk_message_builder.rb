class SktalkMessageBuilder
  class << self
    delegate :uuid, to: SecureRandom
  end

  def initialize(class:, posp_id: nil, posp_version: nil, message_id: uuid, correlation_id: uuid, reference_id: nil, business_id: nil) # TODO channel_info: nil, channel_info_reply: nil, security_method: nil, security_token: nil, identity: nil
    Nokogiri::XML::Builder.new(encoding: 'utf-8') { |m|
      @builder = m
      m.SKTalkMessage {
        m.parent[:xmlns] = 'http://gov.sk/SKTalkMessage'
        m.EnvelopeVersion '3.0'
        m.Header {
          m.MessageInfo {
            m.Class binding.local_variable_get(:class)
            m.PospID posp_id if posp_id
            m.PospVersion posp_version if posp_version
            m.MessageID message_id
            m.CorrelationID correlation_id
            m.ReferenceID reference_id if reference_id
            m.BusinessID business_id if business_id
            # TODO support channel info
            # m.ChannelInfo channel_info if channel_info
            # m.ChannelInfoReply channel_info_reply if channel_info_reply
          }
          # TODO support sender info
          # m.SenderInfo {
          #   m.SecurityMethod security_method if security_method
          #   m.SecurityToken security_token if security_token
          #   m.Identity identity if identity
          # } if security_method || security_token || identity
          # TODO support routing info
          # m.RoutingInfo {
          # }
        }
        m.Body {
          yield self if block_given?
        }
      }
    }
  end

  def message_container(sender_uri:, recipient_uri:, message_type:, message_subject: nil, sender_business_reference: nil, recipient_business_reference: nil)
    @builder.tap do |m|
      m.MessageContainer {
        m.parent[:xmlns] = 'http://schemas.gov.sk/core/MessageContainer/1.0'
        m.MessageId @builder.doc.at_xpath('/SKTalkMessage/Header/MessageInfo/MessageID').content
        m.SenderId sender_uri
        m.RecipientId recipient_uri
        m.MessageType message_type
        m.MessageSubject message_subject if message_subject
        m.SenderBusinessReference sender_business_reference if sender_business_reference
        m.RecipientBusinessReference recipient_business_reference if recipient_business_reference
        yield self if block_given?
      }
    end
  end

  def object(id: uuid, name: nil, description: nil, class:, signed: false, mime_type:, encoding:)
    @builder.tap do |m|
      m.Object {
        # TODO fix: attributes in resulting XML are not in order as defined here
        m.parent[:Id] = id
        m.parent[:Name] = name if name
        m.parent[:Description] = description if description
        m.parent[:Class] = binding.local_variable_get(:class)
        m.parent[:IsSigned] = signed
        m.parent[:MimeType] = mime_type
        m.parent[:Encoding] = encoding
        yield self if block_given?
      }
    end
  end

  def form_object(**args, &block)
    raise ArgumentError if args.key?(:class)
    object(**args.merge(class: 'FORM').reverse_merge(mime_type: 'application/x-eform-xml', encoding: 'XML'), &block)
  end

  def attachment_object(**args, &block)
    raise ArgumentError if args.key?(:class)
    object(**args.merge(class: 'ATTACHMENT').reverse_merge(encoding: 'Base64'), &block)
  end

  def <<(value)
    @builder << value.encode(xml: :text)
  end

  delegate :uuid, to: self
  delegate :to_xml, to: :@builder

  private

  # internal support for builders which set SKTalk class or POSP later according to SKTalk body structure

  CLASS_PATH = '/SKTalkMessage/Header/MessageInfo/Class'
  POSP_ID_PATH = '/SKTalkMessage/Header/MessageInfo/PospID'
  POSP_VERSION_PATH = '/SKTalkMessage/Header/MessageInfo/PospVersion'
  MESSAGE_TYPE_PATH = '/SKTalkMessage/Body/MessageContainer/MessageType'

  def set_class(c)
    @builder.doc.at_xpath(CLASS_PATH).content = c
  end

  def set_posp(id, version = nil, set_message_type: false)
    @builder.doc.at_xpath(POSP_ID_PATH).content = id
    @builder.doc.at_xpath(POSP_VERSION_PATH).content = version
    set_message_type(id) if set_message_type
  end

  def set_message_type(type)
    @builder.doc.at_xpath(MESSAGE_TYPE_PATH).content = type
  end

  def posp_id
    @builder.doc.at_xpath(POSP_ID_PATH).content
  end

  def posp_version
    @builder.doc.at_xpath(POSP_VERSION_PATH).content
  end

  def form_schema
    "http://schemas.gov.sk/form/#{posp_id}/#{posp_version}"
  end

  private_constant *constants(false)
end
