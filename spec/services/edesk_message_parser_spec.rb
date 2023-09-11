require 'rails_helper'

RSpec.describe EdeskMessageParser do
  describe '.parse' do
    it 'parses general agenda document message structure' do
      edesk_message = ekr_response('eks/get_message/class/egov_document_response.xml').get_message_result.value

      message = subject.parse(edesk_message)

      expect(message).to have_attributes(
        id: 4898662475,
        klass: 'EGOV_DOCUMENT',
        message_id: '7acc32dd-1586-4103-8634-ba0707820e2e',
        correlation_id: '8a6a31c1-0d54-46c8-aac1-12465162b913',
        subject: 'Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia',
        original_html: start_with('<!DOCTYPE html'),
        original_xml: start_with('<SKTalkMessage'),
        delivered_at: '2017-03-22T11:49:43.357+01:00'.to_time,
        posp_id: 'Doc.GeneralAgendaFiction',
        posp_version: '1.5',
        reference_id: '00000000-0000-0000-0000-000000000000',
        sender_uri: 'ico://sk/42156424_90000',
        recipient_uri: 'ico://sk/83110656',
        type: 'Doc.GeneralAgendaFiction',
        sender_business_reference: nil,
        recipient_business_reference: nil,
        objects: [
          have_attributes(
            id: 'a8529890-258c-4be8-8a71-28a66e523730',
            name: 'Všeobecná agenda - Všeobecná agenda - rozhodnutie do vlastných rúk s fikciou doručenia',
            description: nil,
            klass: 'FORM',
            signed: false,
            mime_type: 'application/x-eform-xml',
            encoding: 'XML',
            content: start_with('<GeneralAgenda')
          )
        ],
        delivery_notification: nil,
        parse_error: nil
      )
    end

    it 'parses delivery report notification message structure' do
      edesk_message = ekr_response('eks/get_message/class/ed_delivery_notification_response.xml').get_message_result.value

      message = subject.parse(edesk_message)

      expect(message).to have_attributes(
        id: 4898663168,
        klass: 'ED_DELIVERY_NOTIFICATION',
        message_id: '765439ee-d757-4917-9ff3-5e77a169345a',
        correlation_id: '3f7e5397-d823-4715-a138-a0127832b184',
        subject: 'Doručenka',
        original_html: start_with('<!DOCTYPE html'),
        original_xml: start_with('<SKTalkMessage'),
        delivered_at: '2017-03-23T09:31:09.580+01:00'.to_time,
        posp_id: nil,
        posp_version: nil,
        reference_id: 'ec8c3281-b038-4637-bf8a-b8ebed8cca05',
        sender_uri: 'ico://sk/42156424_90000',
        recipient_uri: 'ico://sk/83110656',
        type: 'ED.DeliveryReportNotification',
        sender_business_reference: 'ec8c3281-b038-4637-bf8a-b8ebed8cca05',
        recipient_business_reference: nil,
        objects: [
          have_attributes(
            id: '03114956-3301-4b5e-b280-4fddf38ee3b4',
            name: 'Doručenka',
            description: nil,
            klass: 'FORM',
            signed: false,
            mime_type: 'application/x-eform-xml',
            encoding: 'XML',
            content: start_with('<DeliveryReportNotification')
          )
        ],
        delivery_notification: have_attributes(
          consignment: have_attributes(
            message_id: 'ec8c3281-b038-4637-bf8a-b8ebed8cca05',
            message_subject: 'Všeobecná agenda - rozhodnutie do vlastných rúk',
            message_type: 'Doc.GeneralAgendaReport',
            attachments: [
              have_attributes(
                id: 'd69d59d6-7d57-4995-8423-f8de5ca3e9f6',
                name: 'Všeobecná agenda - rozhodnutie do vlastných rúk'
              )
            ],
            note: 'Po uplynutí dátumu doručenia sa doručovaná správa považuje za nedoručenú.'
          ),
          delivery_period: 15,
          delivery_period_end_at: '2017-04-08T00:00:00.00000000+02:00'.to_time,
          received_at: '2017-03-23T09:31:06.72098610+01:00'.to_time
        ),
        parse_error: nil
      )
    end

    it 'parses empty message structure by marking it with parse error' do
      edesk_message = ekr_response('eks/get_message/class/ed_delivery_notification_response.xml').get_message_result.value

      cache_java_object_proxy!(edesk_message)

      expect(edesk_message).to receive_message_chain(:sk_talk, :value).and_return(nil)

      message = subject.parse(edesk_message)

      expect(message).to have_attributes(
        id: 4898663168,
        klass: 'ED_DELIVERY_NOTIFICATION',
        message_id: '765439ee-d757-4917-9ff3-5e77a169345a',
        correlation_id: '3f7e5397-d823-4715-a138-a0127832b184',
        subject: 'Doručenka',
        original_html: start_with('<!DOCTYPE html'),
        original_xml: nil,
        delivered_at: '2017-03-23T09:31:09.580+01:00'.to_time,
        posp_id: nil,
        posp_version: nil,
        reference_id: nil,
        sender_uri: nil,
        recipient_uri: nil,
        type: nil,
        sender_business_reference: nil,
        recipient_business_reference: nil,
        objects: [],
        delivery_notification: nil,
        parse_error: kind_of(EdeskMessageParser::ParseError)
      )
    end

    it 'parses broken message structure by marking it with parse error' do
      edesk_message = ekr_response('eks/get_message/class/ed_delivery_notification_response.xml').get_message_result.value

      cache_java_object_proxy!(edesk_message)

      expect(edesk_message).to receive_message_chain(:sk_talk, :value).and_return('broken')

      message = subject.parse(edesk_message)

      expect(message).to have_attributes(
        id: 4898663168,
        klass: 'ED_DELIVERY_NOTIFICATION',
        message_id: '765439ee-d757-4917-9ff3-5e77a169345a',
        correlation_id: '3f7e5397-d823-4715-a138-a0127832b184',
        subject: 'Doručenka',
        original_html: start_with('<!DOCTYPE html'),
        original_xml: 'broken',
        delivered_at: '2017-03-23T09:31:09.580+01:00'.to_time,
        posp_id: nil,
        posp_version: nil,
        reference_id: nil,
        sender_uri: nil,
        recipient_uri: nil,
        type: nil,
        sender_business_reference: nil,
        recipient_business_reference: nil,
        objects: [],
        delivery_notification: nil,
        parse_error: kind_of(EdeskMessageParser::ParseError)
      )
    end

    it 'parses unknown message structure by marking it with parse error' do
      edesk_message = ekr_response('eks/get_message/class/ed_delivery_notification_response.xml').get_message_result.value

      cache_java_object_proxy!(edesk_message)

      expect(edesk_message).to receive_message_chain(:sk_talk, :value).and_return(file_fixture('sktalk/ed_authorize.xml').read)

      message = subject.parse(edesk_message)

      expect(message).to have_attributes(
        id: 4898663168,
        klass: 'ED_DELIVERY_NOTIFICATION',
        message_id: '765439ee-d757-4917-9ff3-5e77a169345a',
        correlation_id: '3f7e5397-d823-4715-a138-a0127832b184',
        subject: 'Doručenka',
        original_html: start_with('<!DOCTYPE html'),
        original_xml: start_with('<?xml version="1.0"'),
        delivered_at: '2017-03-23T09:31:09.580+01:00'.to_time,
        posp_id: nil,
        posp_version: nil,
        reference_id: nil,
        sender_uri: nil,
        recipient_uri: nil,
        type: nil,
        sender_business_reference: nil,
        recipient_business_reference: nil,
        objects: [],
        delivery_notification: nil,
        parse_error: kind_of(EdeskMessageParser::ParseError)
      )
    end

    fixture_names('eks/get_message/class/*.xml').each do |fixture|
      it "parses #{fixture_name_to_human(fixture)} message structure without parse error" do
        edesk_message = ekr_response(fixture).get_message_result.value

        message = subject.parse(edesk_message)

        expect(message.parse_error).to be_nil
      end
    end
  end
end
