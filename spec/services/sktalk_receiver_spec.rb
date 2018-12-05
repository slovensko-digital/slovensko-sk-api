require 'rails_helper'

RSpec.describe SktalkReceiver, :upvs do
  let(:properties) { UpvsEnvironment.properties }
  let(:upvs) { UpvsProxy.new(properties) }

  let(:message) { file_fixture('sktalk/egov_application_general_agenda.xml').read }

  subject { described_class.new(upvs) }

  before(:example) { cache_java_object_proxy!(upvs.sktalk) }

  describe '#receive' do
    it 'receives message' do
      expect(upvs.sktalk).to receive(:receive).with(message_of_class('EGOV_APPLICATION')).and_call_original

      expect(subject.receive(message)).to be_an(Integer)
    end

    pending 'raises error on timeout'
  end

  describe '#save_to_outbox' do
    it 'saves message to outbox' do
      expect(upvs.sktalk).to receive(:receive).with(message_of_class('EDESK_SAVE_APPLICATION_TO_OUTBOX')).and_call_original

      expect(subject.receive(message)).to be_an(Integer)
    end

    pending 'raises error on timeout'
  end
end
