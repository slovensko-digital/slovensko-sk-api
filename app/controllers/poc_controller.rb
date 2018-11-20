# TODO rm

class PocController < ApplicationController
  before_action { render_bad_request('No credentials') if params[:key].blank? }
  before_action { render_unauthorized if assertion.blank? }
  before_action { render_bad_request('No recipient') if params[:recipient_id].blank? }

  def try
    upvs = UpvsEnvironment.upvs_proxy(assertion)

    receiver = SktalkReceiver.new(upvs)
    saver = SktalkSaver.new(receiver)

    message = SktalkMessages.from_xml(File.read('spec/examples/fixtures/egov_application_general_agenda.xml'))
    info = message.header.message_info
    info.message_id = SecureRandom.uuid
    info.correlation_id = SecureRandom.uuid
    body = Nokogiri::XML::Document.wrap(message.body.any.first.owner_document)
    container = body.xpath('/:MessageContainer')
    container.xpath('./:MessageId').first.content = info.message_id
    container.xpath('./:SenderId').first.content = Nokogiri::XML.parse(assertion).xpath('//saml:Attribute[@Name="SubjectID"]').first.content
    container.xpath('./:RecipientId').first.content = params[:recipient_id]
    message = SktalkMessages.to_xml(message)

    receive_result = receiver.receive(message)
    save_to_outbox_result = saver.save_to_outbox(message)

    render json: { message: message, receive_result: receive_result, save_to_outbox_result: save_to_outbox_result }
  end

  private

  def assertion
    @assertion ||= UpvsEnvironment.assertion_store.read(params[:key])
  end
end
