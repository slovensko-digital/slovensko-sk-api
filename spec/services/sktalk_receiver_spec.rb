require 'rails_helper'

# NOTE: requires UPVS technical account with UIR access

RSpec.describe SktalkReceiver, :sts do
  let(:properties) { UpvsEnvironment.properties(sub: corporate_body_subject) }
  let(:upvs) { UpvsProxy.new(properties) }

  subject { described_class.new(upvs) }

  before(:example) { allow_upvs_expectations! }

  def sktalk_message(class: 'EGOV_APPLICATION', subject: 'Všeobecný predmet', body: 'Všeobecný text')
    EgovMessageBuilder.new_application { |m|
      m.message_container(sender_uri: 'ico://sk/6501017042', recipient_uri: 'ico://sk/8311237188') {
        m.form_object {
          m.general_agenda(subject: subject, body: body)
        }
      }
    }.instance_exec {
      self.tap { set_class(binding.local_variable_get(:class)) }
    }.to_xml
  end

  # TODO test this on: #receive, #receive_and_save_to_outbox!, #save_to_outbox
  # TODO add notes about this to each endpoint in API specification
  #
  # Poznámka: Maximálna veľkosť spracovávanej správy je 50MB (51200kB). Pri používaní base64 kódovania objektov je obvykle
  # možné prenášať len súbory v celkovej veľkosti približne 34 MB, nakoľko base64 kódovanie zväčšuje veľkosť súborov približne
  # o tretinu.
  #
  # X -> largest message -> receive_result: 0
  # pending 'with largest message' do
  #   let(:message) { sktalk_message(body: 'B' * X) }
  #
  #   it 'raises error' do
  #     expect { subject.receive(message) }.to raise_error(RuntimeError)
  #   end
  # end
  #
  # 40.megabytes -> receive_result: 3100130 -> is this some "too large" error? OR Java::JavaxXmlWs::WebServiceException: Could not send Message.
  # pending 'with message too large' do
  #   let(:message) { sktalk_message(body: 'B' * 40.megabytes) }
  #
  #   it 'raises error' do
  #     expect { subject.receive(message) }.to raise_error(RuntimeError)
  #   end
  # end
  #
  # 50.megabytes -> Java::JavaxXmlWsSoap::SOAPFaultException: Error in deserializing body of request message for operation 'Receive'.
  # pending 'with oversized message' do
  #   let(:message) { sktalk_message(body: 'B' * 50.megabytes) }
  #
  #   it 'raises error' do
  #     expect { subject.receive(message) }.to raise_error(RuntimeError)
  #   end
  # end

  describe '#receive' do
    let(:message) { sktalk_message }

    it 'receives message' do
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EGOV_APPLICATION')).and_call_original

      expect(subject.receive(message)).to eq(0)
    end

    context 'with invalid message' do
      let(:message) { 'INVALID' }

      it 'does not receive message' do
        expect(upvs.sktalk).not_to receive(:receive)

        suppress(SktalkReceiver::ReceiveMessageFormatError) { subject.receive(message) }
      end

      it 'raises error' do
        expect { subject.receive(message) }.to raise_error(SktalkReceiver::ReceiveMessageFormatError)
      end
    end

    context 'with message being saved to drafts' do
      let(:message) { sktalk_message(class: 'EDESK_SAVE_APPLICATION_TO_DRAFTS') }

      it 'does not receive message' do
        expect(upvs.sktalk).not_to receive(:receive)

        suppress(SktalkReceiver::ReceiveAsSaveToFolderError) { subject.receive(message) }
      end

      it 'raises error' do
        expect { subject.receive(message) }.to raise_error(SktalkReceiver::ReceiveAsSaveToFolderError)
      end
    end

    context 'with message being saved to outbox' do
      let(:message) { sktalk_message(class: 'EDESK_SAVE_APPLICATION_TO_OUTBOX') }

      it 'does not receive message' do
        expect(upvs.sktalk).not_to receive(:receive)

        suppress(SktalkReceiver::ReceiveAsSaveToFolderError) { subject.receive(message) }
      end

      it 'raises error' do
        expect { subject.receive(message) }.to raise_error(SktalkReceiver::ReceiveAsSaveToFolderError)
      end
    end

    context 'with message returning non-zero result' do
      let(:message) { sktalk_message(class: nil) }

      it 'receives message' do
        expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class(nil)).and_call_original

        expect(subject.receive(message)).to eq(3100119)
      end
    end

    include_examples 'UPVS proxy internals', -> { subject.receive(message) }
  end

  describe '#receive!' do
    pending # TODO
  end

  describe '#receive_and_save_to_outbox!' do
    let(:message) { sktalk_message }

    it 'receives message and saves it to outbox' do
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EGOV_APPLICATION')).and_call_original
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EDESK_SAVE_APPLICATION_TO_OUTBOX')).and_call_original

      expect(subject.receive_and_save_to_outbox!(message)).to have_attributes(receive_result: 0, receive_timeout: false, save_to_outbox_result: 0, save_to_outbox_timeout: false)
    end

    context 'with invalid message' do
      let(:message) { 'INVALID' }

      it 'does not receive message or save it to outbox' do
        expect(upvs.sktalk).not_to receive(:receive)

        suppress(SktalkReceiver::ReceiveMessageFormatError) { subject.receive_and_save_to_outbox!(message) }
      end

      it 'raises error' do
        expect { subject.receive_and_save_to_outbox!(message) }.to raise_error(SktalkReceiver::ReceiveMessageFormatError)
      end
    end

    context 'with message being saved to drafts' do
      let(:message) { sktalk_message(class: 'EDESK_SAVE_APPLICATION_TO_DRAFTS') }

      it 'does not receive message or save it to outbox' do
        expect(upvs.sktalk).not_to receive(:receive)

        suppress(SktalkReceiver::ReceiveAsSaveToFolderError) { subject.receive_and_save_to_outbox!(message) }
      end

      it 'raises error' do
        expect { subject.receive_and_save_to_outbox!(message) }.to raise_error(SktalkReceiver::ReceiveAsSaveToFolderError)
      end
    end

    context 'with message being saved to outbox' do
      let(:message) { sktalk_message(class: 'EDESK_SAVE_APPLICATION_TO_OUTBOX') }

      it 'does not receive message or save it to outbox' do
        expect(upvs.sktalk).not_to receive(:receive)

        suppress(SktalkReceiver::ReceiveAsSaveToFolderError) { subject.receive_and_save_to_outbox!(message) }
      end

      it 'raises error' do
        expect { subject.receive_and_save_to_outbox!(message) }.to raise_error(SktalkReceiver::ReceiveAsSaveToFolderError)
      end
    end

    context 'with message returning non-zero result on receive' do
      it 'does not receive message or save it to outbox' do
        expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EGOV_APPLICATION')).and_return(3100119)
        expect(upvs.sktalk).not_to receive(:receive).with(sktalk_message_of_class('EDESK_SAVE_APPLICATION_TO_OUTBOX'))

        expect(subject.receive_and_save_to_outbox!(message)).to have_attributes(receive_result: 3100119, receive_timeout: false, save_to_outbox_result: nil, save_to_outbox_timeout: nil)
      end
    end

    context 'with timeout on receive' do
      it 'timeouts on receiving message and does not save it to outbox' do
        expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EGOV_APPLICATION')).and_raise(soap_timeout_exception)
        expect(upvs.sktalk).not_to receive(:receive).with(sktalk_message_of_class('EDESK_SAVE_APPLICATION_TO_OUTBOX'))

        expect(subject.receive_and_save_to_outbox!(message)).to have_attributes(receive_result: nil, receive_timeout: true, save_to_outbox_result: nil, save_to_outbox_timeout: nil)
      end
    end

    context 'with message returning non-zero result on save to outbox' do
      it 'receives message but does not save it to outbox' do
        expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EGOV_APPLICATION')).and_return(0)
        expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EDESK_SAVE_APPLICATION_TO_OUTBOX')).and_return(3100119)

        expect(subject.receive_and_save_to_outbox!(message)).to have_attributes(receive_result: 0, receive_timeout: false, save_to_outbox_result: 3100119, save_to_outbox_timeout: false)
      end
    end

    context 'with timeout on save to outbox' do
      it 'receives message but timeouts on saving it to outbox' do
        expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EGOV_APPLICATION')).and_return(0)
        expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EDESK_SAVE_APPLICATION_TO_OUTBOX')).and_raise(soap_timeout_exception)

        expect(subject.receive_and_save_to_outbox!(message)).to have_attributes(receive_result: 0, receive_timeout: false, save_to_outbox_result: nil, save_to_outbox_timeout: true)
      end
    end

    include_examples 'UPVS proxy internals', -> { subject.receive_and_save_to_outbox!(message) }, exclude_timeout_examples: true
  end

  describe '#save_to_outbox' do
    let(:message) { sktalk_message }

    it 'saves message to outbox' do
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EDESK_SAVE_APPLICATION_TO_OUTBOX')).and_call_original

      expect(subject.save_to_outbox(message)).to eq(0)
    end

    context 'with invalid message' do
      let(:message) { 'INVALID' }

      it 'does not save message to outbox' do
        expect(upvs.sktalk).not_to receive(:receive)

        suppress(SktalkReceiver::ReceiveMessageFormatError) { subject.save_to_outbox(message) }
      end

      it 'raises error' do
        expect { subject.save_to_outbox(message) }.to raise_error(SktalkReceiver::ReceiveMessageFormatError)
      end
    end

    context 'with message being saved to drafts' do
      let(:message) { sktalk_message(class: 'EDESK_SAVE_APPLICATION_TO_DRAFTS') }

      it 'does not save message to outbox' do
        expect(upvs.sktalk).not_to receive(:receive)

        suppress(SktalkReceiver::ReceiveAsSaveToFolderError) { subject.save_to_outbox(message) }
      end

      it 'raises error' do
        expect { subject.save_to_outbox(message) }.to raise_error(SktalkReceiver::ReceiveAsSaveToFolderError)
      end
    end

    context 'with message being saved to outbox' do
      let(:message) { sktalk_message(class: 'EDESK_SAVE_APPLICATION_TO_OUTBOX') }

      it 'does not save message to outbox' do
        expect(upvs.sktalk).not_to receive(:receive)

        suppress(SktalkReceiver::ReceiveAsSaveToFolderError) { subject.save_to_outbox(message) }
      end

      it 'raises error' do
        expect { subject.save_to_outbox(message) }.to raise_error(SktalkReceiver::ReceiveAsSaveToFolderError)
      end
    end

    context 'with message returning non-zero result' do
      let(:message) { sktalk_message(class: nil) }

      it 'does not save message to outbox' do
        expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class(nil)).and_call_original

        expect(subject.save_to_outbox(message)).to eq(3100119)
      end
    end

    include_examples 'UPVS proxy internals', -> { subject.save_to_outbox(message) }
  end
end
