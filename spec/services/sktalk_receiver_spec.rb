require 'rails_helper'

RSpec.describe SktalkReceiver, :upvs do
  let(:properties) { UpvsEnvironment.properties(assertion: nil) }
  let(:upvs) { UpvsProxy.new(properties) }

  let(:message) { file_fixture('sktalk/egov_application_general_agenda.xml').read }

  subject { described_class.new(upvs) }

  before(:example) { cache_java_object_proxy!(upvs.sktalk) }

  before(:example) { message.gsub!(/(MessageID)>.*</i, "\\1>#{SecureRandom.uuid}<") }

  describe '#receive' do
    it 'receives message' do
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EGOV_APPLICATION')).and_call_original

      expect(subject.receive(message)).to eq(0)
    end

    context 'with malformed message' do
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
      let(:message) { file_fixture('sktalk/edesk_save_application_to_drafts_general_agenda.xml').read }

      it 'does not receive message' do
        expect(upvs.sktalk).not_to receive(:receive)

        suppress(SktalkReceiver::ReceiveAsSaveToFolderError) { subject.receive(message) }
      end

      it 'raises error' do
        expect { subject.receive(message) }.to raise_error(SktalkReceiver::ReceiveAsSaveToFolderError)
      end
    end

    context 'with message being saved to outbox' do
      let(:message) { file_fixture('sktalk/edesk_save_application_to_outbox_general_agenda.xml').read }

      it 'does not receive message' do
        expect(upvs.sktalk).not_to receive(:receive)

        suppress(SktalkReceiver::ReceiveAsSaveToFolderError) { subject.receive(message) }
      end

      it 'raises error' do
        expect { subject.receive(message) }.to raise_error(SktalkReceiver::ReceiveAsSaveToFolderError)
      end
    end

    context 'with message returning non-zero result' do
      let(:message) { super.sub(/(Class)>.*</, '\1><') }

      it 'receives message' do
        expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class(nil)).and_call_original

        expect(subject.receive(message)).to eq(3100119)
      end
    end

    context 'with connection timeout' do
      let(:properties) { UpvsEnvironment.properties(assertion: nil).merge('upvs.timeout.connection' => 2) }

      it 'raises error' do
        expect { subject.receive(message) }.to raise_error(javax.xml.ws.soap.SOAPFaultException, /connect timed out/i)
      end
    end

    context 'with receive timeout' do
      let(:properties) { UpvsEnvironment.properties(assertion: nil).merge('upvs.timeout.receive' => 2) }

      it 'raises error' do
        expect { subject.receive(message) }.to raise_error(javax.xml.ws.soap.SOAPFaultException, /read timed out/i)
      end
    end
  end

  describe '#receive_and_save_to_outbox!' do
    it 'receives message and saves it to outbox' do
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EGOV_APPLICATION')).and_call_original
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EDESK_SAVE_APPLICATION_TO_OUTBOX')).and_call_original

      expect(subject.receive_and_save_to_outbox!(message)).to have_attributes(receive_result: 0, receive_timeout: false, save_to_outbox_result: 0, save_to_outbox_timeout: false)
    end

    context 'with malformed message' do
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
      let(:message) { file_fixture('sktalk/edesk_save_application_to_drafts_general_agenda.xml').read }

      it 'does not receive message or save it to outbox' do
        expect(upvs.sktalk).not_to receive(:receive)

        suppress(SktalkReceiver::ReceiveAsSaveToFolderError) { subject.receive_and_save_to_outbox!(message) }
      end

      it 'raises error' do
        expect { subject.receive_and_save_to_outbox!(message) }.to raise_error(SktalkReceiver::ReceiveAsSaveToFolderError)
      end
    end

    context 'with message being saved to outbox' do
      let(:message) { file_fixture('sktalk/edesk_save_application_to_outbox_general_agenda.xml').read }

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
        expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EGOV_APPLICATION')).and_raise(soap_fault_exception('connect timed out'))
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
        expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EDESK_SAVE_APPLICATION_TO_OUTBOX')).and_raise(soap_fault_exception('connect timed out'))

        expect(subject.receive_and_save_to_outbox!(message)).to have_attributes(receive_result: 0, receive_timeout: false, save_to_outbox_result: nil, save_to_outbox_timeout: true)
      end
    end
  end

  describe '#save_to_outbox' do
    it 'saves message to outbox' do
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EDESK_SAVE_APPLICATION_TO_OUTBOX')).and_call_original

      expect(subject.save_to_outbox(message)).to eq(0)
    end

    context 'with malformed message' do
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
      let(:message) { file_fixture('sktalk/edesk_save_application_to_drafts_general_agenda.xml').read }

      it 'does not save message to outbox' do
        expect(upvs.sktalk).not_to receive(:receive)

        suppress(SktalkReceiver::ReceiveAsSaveToFolderError) { subject.save_to_outbox(message) }
      end

      it 'raises error' do
        expect { subject.save_to_outbox(message) }.to raise_error(SktalkReceiver::ReceiveAsSaveToFolderError)
      end
    end

    context 'with message being saved to outbox' do
      let(:message) { file_fixture('sktalk/edesk_save_application_to_outbox_general_agenda.xml').read }

      it 'does not save message to outbox' do
        expect(upvs.sktalk).not_to receive(:receive)

        suppress(SktalkReceiver::ReceiveAsSaveToFolderError) { subject.save_to_outbox(message) }
      end

      it 'raises error' do
        expect { subject.save_to_outbox(message) }.to raise_error(SktalkReceiver::ReceiveAsSaveToFolderError)
      end
    end

    context 'with message returning non-zero result' do
      let(:message) { super.sub(/(Class)>.*</, '\1><') }

      it 'does not save message to outbox' do
        expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class(nil)).and_call_original

        expect(subject.save_to_outbox(message)).to eq(3100119)
      end
    end

    context 'with connection timeout' do
      let(:properties) { UpvsEnvironment.properties(assertion: nil).merge('upvs.timeout.connection' => 2) }

      it 'raises error' do
        expect { subject.save_to_outbox(message) }.to raise_error(javax.xml.ws.soap.SOAPFaultException, /connect timed out/i)
      end
    end

    context 'with receive timeout' do
      let(:properties) { UpvsEnvironment.properties(assertion: nil).merge('upvs.timeout.receive' => 2) }

      it 'raises error' do
        expect { subject.save_to_outbox(message) }.to raise_error(javax.xml.ws.soap.SOAPFaultException, /read timed out/i)
      end
    end
  end
end
