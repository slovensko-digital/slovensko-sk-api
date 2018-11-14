# TODO rm

class PocController < ApplicationController
  before_action { render_bad_request('No credentials') unless session[:key] }
  before_action { render_unauthorized unless assertion }

  def try
    upvs = UpvsEnvironment.upvs_proxy(assertion)

    receiver = SktalkReceiver.new(upvs)
    saver = SktalkSaver.new(receiver)

    message = SktalkMessages.from_xml(File.read('tmp/egov_application_csru_generic.xml'))
    info = message.header.message_info
    info.message_id = SecureRandom.uuid
    info.correlation_id = SecureRandom.uuid
    body = Nokogiri::XML::Document.wrap(message.body.any.first.owner_document)
    container = body.xpath('/:MessageContainer')
    container.xpath('./:MessageId').first.content = info.message_id
    container.xpath('./:SenderId').first.content = Nokogiri::XML.parse(assertion).xpath('//saml:Attribute[@Name="SubjectID"]').first.content
    container.xpath('./:RecipientId').first.content = 'ico://sk/8311237188'
    message = SktalkMessages.to_xml(message)

    receive_result = receiver.receive(message)
    save_to_outbox_result = saver.save_to_outbox(message)

    render json: { message: message, receive_result: receive_result, save_to_outbox_result: save_to_outbox_result }
  end

  private

  def assertion
    @assertion ||= UpvsEnvironment.assertion_store.read(session[:key])
  end
end
