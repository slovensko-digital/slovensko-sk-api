require 'rails_helper'

# NOTE: requires UPVS technical account with EKR access to eDesk and UIR access

RSpec.describe EdeskService, :sts do
  let(:properties) { UpvsEnvironment.properties(sub: corporate_body_subject) }
  let(:upvs) { UpvsProxy.new(properties) }

  subject { described_class.new(upvs) }

  let(:inbox) { subject.folders.find { |folder| folder.name.value == 'Inbox' } || raise('No inbox') }
  let(:notification) { subject.messages(inbox.id_folder, per_page: 10_000).find { |message| message.clazz.value == 'ED_DELIVERY_NOTIFICATION' } || raise('No notification') }

  before(:example) { allow_upvs_expectations! }

  describe '#folders' do
    it 'reads folders' do
      expect(upvs.eks).to receive(:get_folders).and_call_original

      folders = subject.folders

      expect(folders).not_to be_empty
      expect(folders).to all be_a org.datacontract.schemas._2004._07.anasoft_edesk_edeskii.Folder
    end

    include_examples 'UPVS proxy internals', -> { subject.folders }
  end

  describe '#messages' do
    it 'reads messages' do
      expect(upvs.eks).to receive(:get_messages).with(inbox.id_folder, 50, 0).and_call_original

      messages = subject.messages(inbox.id_folder)

      expect(messages).not_to be_empty
      expect(messages).to all be_a org.datacontract.schemas._2004._07.anasoft_edesk_edeskii.Message
    end

    context 'with pagination' do
      it 'uses given page number' do
        expect(upvs.eks).to receive(:get_messages).with(inbox.id_folder, 50, 200).and_call_original

        subject.messages(inbox.id_folder, page: 5)
      end

      it 'uses given per page number' do
        expect(upvs.eks).to receive(:get_messages).with(inbox.id_folder, 10, 0).and_call_original

        subject.messages(inbox.id_folder, per_page: 10)
      end
    end

    context 'with inaccessible folder' do
      it 'raises error' do
        expect { subject.messages(1) }.to raise_error(sk.gov.schemas.edesk.eksservice._1.IEKSServiceGetMessagesEDeskFaultFaultFaultMessage, 'Užívateľ nemá právo čítať daný priečinok.')
      end
    end

    context 'with non-existing folder' do
      it 'raises error' do
        # TODO this is probably another bug in eDesk API -> it should result in "Priečinok neexistuje." error
        expect { subject.messages(0) }.to raise_error(sk.gov.schemas.edesk.eksservice._1.IEKSServiceGetMessagesEDeskFaultFaultFaultMessage, 'Užívateľ nemá právo čítať daný priečinok.')
      end
    end

    include_examples 'UPVS proxy internals', -> { subject.messages(0) }
  end

  describe '#message' do
    it 'reads message' do
      expect(upvs.eks).to receive(:get_message).with(notification.id_message).and_call_original

      message = subject.message(notification.id_message)

      expect(message).to be_a org.datacontract.schemas._2004._07.anasoft_edesk_edeskii.Message
    end

    context 'with inaccessible message' do
      it 'raises error' do
        # TODO this message belongs to irvin_83110656_fix
        expect { subject.message(4898584833) }.to raise_error(sk.gov.schemas.edesk.eksservice._1.IEKSServiceGetMessageEDeskFaultFaultFaultMessage, 'Užívateľ nemá právo čítať danú správu.')
      end
    end

    context 'with non-existing message' do
      it 'raises error' do
        expect { subject.message(0) }.to raise_error(sk.gov.schemas.edesk.eksservice._1.IEKSServiceGetMessageEDeskFaultFaultFaultMessage, 'Správa neexistuje.')
      end
    end

    include_examples 'UPVS proxy internals', -> { subject.message(0) }
  end

  describe '#authorize_message' do
    it 'authorizes message' do
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_of_class('ED_AUTHORIZE')).and_call_original

      result = subject.authorize_message(notification.id_message)

      expect(result).to eq(0)
    end

    describe 'authorization' do
      before(:example) do
        allow(upvs.eks).to receive(:get_message).and_return(double(sk_talk: double(value: file_fixture('sktalk/ed_delivery_notification.xml').read)))
        allow(upvs.sktalk).to receive(:receive).and_return(0)

        travel_to('2016-10-18T16:35:44+02:00') { subject.authorize_message(0) }
      end

      it 'has authorization class' do
        expect(upvs.sktalk).to have_received(:receive).with(sktalk_message_of_class('ED_AUTHORIZE'))
      end

      it 'has notification message ID set as reference ID' do
        expect(upvs.sktalk).to have_received(:receive).with(sktalk_message_referencing('6d65268e-495e-45f4-a3cb-3e8fca85b40a'))
      end

      it 'has notification correlation ID set as correlation ID' do
        expect(upvs.sktalk).to have_received(:receive).with(sktalk_message_in_correlation_with('ac64292e-e06a-4147-8b8c-d56275a9f625'))
      end

      it 'has notification sender URI as recipient URI' do
        expect(upvs.sktalk).to have_received(:receive).with(sktalk_message_containing('ico://sk/42156424_90000', at: '//:RecipientId', xmlns: 'http://schemas.gov.sk/core/MessageContainer/1.0'))
      end

      it 'has notification recipient URI set as sender URI' do
        expect(upvs.sktalk).to have_received(:receive).with(sktalk_message_containing('ico://sk/6501012225', at: '//:SenderId', xmlns: 'http://schemas.gov.sk/core/MessageContainer/1.0'))
      end

      it 'has notification reference ID set as authorized message ID' do
        expect(upvs.sktalk).to have_received(:receive).with(sktalk_message_containing('e411c801-8290-47c2-8250-801f3cf56e58', at: '//:MessageID', xmlns: 'http://schemas.gov.sk/form/ED.DeliveryReportAuthorization/1.3'))
      end

      it 'has notification recipient URI set as authorization actor URI' do
        expect(upvs.sktalk).to have_received(:receive).with(sktalk_message_containing('ico://sk/6501012225', at: '//:ActorID', xmlns: 'http://schemas.gov.sk/form/ED.DeliveryReportAuthorization/1.3'))
      end

      it 'has notification recipient URI set as authorization subject URI' do
        expect(upvs.sktalk).to have_received(:receive).with(sktalk_message_containing('ico://sk/6501012225', at: '//:SubjectID', xmlns: 'http://schemas.gov.sk/form/ED.DeliveryReportAuthorization/1.3'))
      end

      it 'has current time set as authorization time' do
        expect(upvs.sktalk).to have_received(:receive).with(sktalk_message_containing('2016-10-18T16:35:44+02:00', at: '//:Authorized', xmlns: 'http://schemas.gov.sk/form/ED.DeliveryReportAuthorization/1.3'))
      end
    end

    context 'with inaccessible message' do
      it 'raises error' do
        # TODO this message belongs to irvin_83110656_fix
        expect { subject.authorize_message(4898584833) }.to raise_error(sk.gov.schemas.edesk.eksservice._1.IEKSServiceGetMessageEDeskFaultFaultFaultMessage, 'Užívateľ nemá právo čítať danú správu.')
      end
    end

    context 'with non-existing message' do
      it 'raises error' do
        expect { subject.authorize_message(0) }.to raise_error(sk.gov.schemas.edesk.eksservice._1.IEKSServiceGetMessageEDeskFaultFaultFaultMessage, 'Správa neexistuje.')
      end
    end

    context 'with non-delivery message' do
      it 'raises error' do
        message = subject.messages(inbox.id_folder, per_page: 10_000).find { |message| message.clazz.value != 'ED_DELIVERY_NOTIFICATION' } || raise('No message')

        expect { subject.authorize_message(message.id_message) }.to raise_error(EdeskService::AuthorizeMessageTypeError)
      end
    end

    include_examples 'UPVS proxy internals', -> { subject.authorize_message(0) }
  end

  describe '#delete_message' do
    it 'deletes message' do
      # TODO it would be nice to actually delete the message
      expect(upvs.eks).to receive(:delete_message).with(notification.id_message).and_return(true)

      result = subject.delete_message(notification.id_message)

      expect(result).to eq(true)
    end

    context 'with inaccessible message' do
      it 'raises error' do
        # TODO this message belongs to irvin_83110656_fix
        expect { subject.delete_message(4898584833) }.to raise_error(sk.gov.schemas.edesk.eksservice._1.IEKSServiceDeleteMessageEDeskFaultFaultFaultMessage, 'Užívateľ nemá právo zmazať danú správu.')
      end
    end

    context 'with non-existing message' do
      it 'returns' do
        expect(subject.delete_message(0)).to eq(true)
      end

      it 'raises error when not forced by default' do
        expect { subject.delete_message(0, force: false) }.to raise_error(sk.gov.schemas.edesk.eksservice._1.IEKSServiceDeleteMessageEDeskFaultFaultFaultMessage, 'Správa neexistuje.')
      end
    end

    include_examples 'UPVS proxy internals', -> { subject.delete_message(0) }
  end

  describe '#move_message' do
    it 'moves message' do
      # TODO it would be nice to actually move the message
      expect(upvs.eks).to receive(:move_message).with(notification.id_message, inbox.id_folder).and_return(nil)

      result = subject.move_message(notification.id_message, inbox.id_folder)

      expect(result).to eq(nil)
    end

    context 'with inaccessible folder' do
      it 'raises error' do
        expect { subject.move_message(notification.id_message, 1) }.to raise_error(sk.gov.schemas.edesk.eksservice._1.IEKSServiceMoveMessageEDeskFaultFaultFaultMessage, 'Užívateľ nemá právo čítať cieľový priečinok.')
      end
    end

    context 'with non-existing folder' do
      it 'raises error' do
        expect { subject.move_message(notification.id_message, 0) }.to raise_error(sk.gov.schemas.edesk.eksservice._1.IEKSServiceMoveMessageEDeskFaultFaultFaultMessage, 'Cieľový priečinok neexistuje.')
      end
    end

    context 'with inaccessible message' do
      it 'raises error' do
        # TODO this message belongs to irvin_83110656_fix
        expect { subject.move_message(4898584833, inbox.id_folder) }.to raise_error(sk.gov.schemas.edesk.eksservice._1.IEKSServiceMoveMessageEDeskFaultFaultFaultMessage, 'Užívateľ nemá právo presunúť správu.')
      end
    end

    context 'with non-existing message' do
      it 'raises error' do
        expect { subject.move_message(0, inbox.id_folder) }.to raise_error(sk.gov.schemas.edesk.eksservice._1.IEKSServiceMoveMessageEDeskFaultFaultFaultMessage, 'Správa neexistuje.')
      end
    end

    include_examples 'UPVS proxy internals', -> { subject.move_message(0, 0) }
  end
end
