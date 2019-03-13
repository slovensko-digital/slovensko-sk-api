require 'rails_helper'

RSpec.describe SktalkReceiver, :upvs do
  let(:properties) { UpvsEnvironment.properties }
  let(:upvs) { UpvsProxy.new(properties) }

  let(:message) { file_fixture('sktalk/egov_application_general_agenda.xml').read }

  subject { described_class.new(upvs) }

  before(:example) { cache_java_object_proxy!(upvs.sktalk) }

  describe '#receive' do
    it 'receives message' do
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EGOV_APPLICATION')).and_call_original

      expect(subject.receive(message)).to be_an(Integer)
    end

    context 'with malformed message' do
      let(:message) { 'INVALID' }

      it 'raises error' do
        expect { subject.receive(message) }.to raise_error(javax.xml.bind.UnmarshalException)
      end
    end

    pending 'with too large message'

    context 'with connection timeout' do
      let(:properties) { UpvsEnvironment.properties.merge('upvs.timeout.connection' => 2) }

      it 'raises error' do
        expect { subject.receive(message) }.to raise_error(javax.xml.ws.soap.SOAPFaultException) do |error|
          expect(error.message).to match(/connect timed out/i)
        end
      end
    end

    context 'with receive timeout' do
      let(:properties) { UpvsEnvironment.properties.merge('upvs.timeout.receive' => 2) }

      it 'raises error' do
        expect { subject.receive(message) }.to raise_error(javax.xml.ws.soap.SOAPFaultException) do |error|
          expect(error.message).to match(/read timed out/i)
        end
      end
    end
  end

  describe '#save_to_outbox' do
    it 'saves message to outbox' do
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('EDESK_SAVE_APPLICATION_TO_OUTBOX')).and_call_original

      expect(subject.save_to_outbox(message)).to be_an(Integer)
    end

    context 'with malformed message' do
      let(:message) { 'INVALID' }

      it 'raises error' do
        expect { subject.save_to_outbox(message) }.to raise_error(javax.xml.bind.UnmarshalException)
      end
    end

    pending 'with too large message'

    context 'with connection timeout' do
      let(:properties) { UpvsEnvironment.properties.merge('upvs.timeout.connection' => 2) }

      it 'raises error' do
        expect { subject.save_to_outbox(message) }.to raise_error(javax.xml.ws.soap.SOAPFaultException) do |error|
          expect(error.message).to match(/connect timed out/i)
        end
      end
    end

    context 'with receive timeout' do
      let(:properties) { UpvsEnvironment.properties.merge('upvs.timeout.receive' => 2) }

      it 'raises error' do
        expect { subject.save_to_outbox(message) }.to raise_error(javax.xml.ws.soap.SOAPFaultException) do |error|
          expect(error.message).to match(/read timed out/i)
        end
      end
    end
  end
end
