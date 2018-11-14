# TODO rm

class PocController < ApplicationController
  before_action { render_bad_request('No credentials') unless session[:assertion] }

  def try
    properties = UpvsEnvironment.upvs_properties(nil)
    properties.merge!('upvs.sts.saml.assertion' => session[:assertion])

    upvs = digital.slovensko.upvs.UpvsProxy.new(properties)

    receiver = SktalkReceiver.new(upvs)
    saver = SktalkSaver.new(receiver)

    template = File.read('tmp/egov_application_csru_generic.xml')
    message = Nokogiri::XML.parse(template)
    message.xpath('//MessageID').each { |e| e.content = (uuid ||= SecureRandom.uuid) }
    message.xpath('//CorrelationID').each { |e| e.content = (uuid ||= SecureRandom.uuid) }
    message.xpath('//SenderId').each { |e| e.content = 'ico://sk/6501017042' }
    message.xpath('//RecipientId').each { |e| e.content = 'ico://sk/8311237188' }
    message = message.to_xml

    receive_result = receiver.receive(message)
    save_to_outbox_result = saver.save_to_outbox(message)

    render json: { message: message, receive_result: receive_result, save_to_outbox_result: save_to_outbox_result }
  end
end
