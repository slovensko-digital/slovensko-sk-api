require 'rails_helper'

RSpec.describe SktalkReceiver, :upvs do
  let(:properties) { UpvsEnvironment.properties(assertion: nil) }
  let(:upvs) { UpvsProxy.new(properties) }

  let(:message) { file_fixture('sktalk/egov_application_general_agenda.xml').read }

  subject { described_class.new(upvs) }

  before(:example) { cache_java_object_proxy!(upvs.sktalk) }

  before(:example) { message.gsub!(/(MessageID)>.*</i, "\\1>#{SecureRandom.uuid}<") }

  describe '#receive' do
    context 'with saving to outbox' do
      it 'receives message and saves it to outbox' do
        expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EGOV_APPLICATION')).and_call_original
        expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EDESK_SAVE_APPLICATION_TO_OUTBOX')).and_call_original

        expect(subject.receive(message, save_to_outbox: true)).to have_attributes(receive_result: 0, save_to_outbox_result: 0)
      end

      context 'with malformed message' do
        let(:message) { 'INVALID' }

        it 'does not receive message or save it to outbox' do
          expect(upvs.sktalk).not_to receive(:receive)

          suppress(SktalkReceiver::ReceiveMessageFormatError) { subject.receive(message, save_to_outbox: true) }
        end

        it 'raises error' do
          expect { subject.receive(message, save_to_outbox: true) }.to raise_error(SktalkReceiver::ReceiveMessageFormatError)
        end
      end

      context 'with message being saved to outbox' do
        let(:message) { file_fixture('sktalk/edesk_save_application_to_outbox_general_agenda.xml').read }

        it 'does not receive message or save it to outbox' do
          expect(upvs.sktalk).not_to receive(:receive)

          suppress(SktalkReceiver::ReceiveAsSaveToOutboxError) { subject.receive(message, save_to_outbox: true) }
        end

        it 'raises error' do
          expect { subject.receive(message, save_to_outbox: true) }.to raise_error(SktalkReceiver::ReceiveAsSaveToOutboxError)
        end
      end

      context 'with message returning non-zero result' do
        let(:message) { super.sub(/(Class)>.*</, '\1><') }

        it 'receives message but does not save it to outbox' do
          expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class(nil)).and_call_original
          expect(upvs.sktalk).not_to receive(:receive).with(sktalk_message_of_class('EDESK_SAVE_APPLICATION_TO_OUTBOX'))

          expect(subject.receive(message, save_to_outbox: true)).to have_attributes(receive_result: 3100119, save_to_outbox_result: nil)
        end
      end

      context 'with connection timeout' do
        let(:properties) { UpvsEnvironment.properties(assertion: nil).merge('upvs.timeout.connection' => 2) }

        it 'raises error' do
          expect { subject.receive(message, save_to_outbox: true) }.to raise_error(javax.xml.ws.soap.SOAPFaultException, /connect timed out/i)
        end
      end

      context 'with receive timeout' do
        let(:properties) { UpvsEnvironment.properties(assertion: nil).merge('upvs.timeout.receive' => 2) }

        it 'raises error' do
          expect { subject.receive(message, save_to_outbox: true) }.to raise_error(javax.xml.ws.soap.SOAPFaultException, /read timed out/i)
        end
      end
    end

    context 'without saving to outbox' do
      it 'receives message' do
        expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EGOV_APPLICATION')).and_call_original

        expect(subject.receive(message, save_to_outbox: false)).to have_attributes(receive_result: 0, save_to_outbox_result: nil)
      end

      context 'with malformed message' do
        let(:message) { 'INVALID' }

        it 'does not receive message' do
          expect(upvs.sktalk).not_to receive(:receive)

          suppress(SktalkReceiver::ReceiveMessageFormatError) { subject.receive(message, save_to_outbox: false) }
        end

        it 'raises error' do
          expect { subject.receive(message, save_to_outbox: false) }.to raise_error(SktalkReceiver::ReceiveMessageFormatError)
        end
      end

      context 'with message being saved to outbox' do
        let(:message) { file_fixture('sktalk/edesk_save_application_to_outbox_general_agenda.xml').read }

        it 'does not receive message' do
          expect(upvs.sktalk).not_to receive(:receive)

          suppress(SktalkReceiver::ReceiveAsSaveToOutboxError) { subject.receive(message, save_to_outbox: false) }
        end

        it 'raises error' do
          expect { subject.receive(message, save_to_outbox: false) }.to raise_error(SktalkReceiver::ReceiveAsSaveToOutboxError)
        end
      end

      context 'with message returning non-zero result' do
        let(:message) { super.sub(/(Class)>.*</, '\1><') }

        it 'receives message' do
          expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class(nil)).and_call_original

          expect(subject.receive(message, save_to_outbox: false)).to have_attributes(receive_result: 3100119, save_to_outbox_result: nil)
        end
      end

      context 'with connection timeout' do
        let(:properties) { UpvsEnvironment.properties(assertion: nil).merge('upvs.timeout.connection' => 2) }

        it 'raises error' do
          expect { subject.receive(message, save_to_outbox: false) }.to raise_error(javax.xml.ws.soap.SOAPFaultException, /connect timed out/i)
        end
      end

      context 'with receive timeout' do
        let(:properties) { UpvsEnvironment.properties(assertion: nil).merge('upvs.timeout.receive' => 2) }

        it 'raises error' do
          expect { subject.receive(message, save_to_outbox: false) }.to raise_error(javax.xml.ws.soap.SOAPFaultException, /read timed out/i)
        end
      end
    end
  end
end
