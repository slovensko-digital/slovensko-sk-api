require 'rails_helper'

# NOTE: requires UPVS technical account with IAM access

RSpec.describe IamRepository, :sts do
  let(:properties) { UpvsEnvironment.properties(sub: public_authority_subject) }
  let(:upvs) { UpvsProxy.new(properties) }

  subject { described_class.new(upvs) }

  before(:example) { allow_upvs_expectations! }

  describe '#identity' do
    it 'returns identity data' do
      identity = subject.identity('6d9dc77b-70ed-432f-abaa-5de8753c967c')

      expect(identity).to be_a sk.gov.schemas.identity.identitydata._1.IdentityData
    end

    it 'finds identity by ID' do
      identity = subject.identity('6d9dc77b-70ed-432f-abaa-5de8753c967c')

      expect(identity.general_data.egov_identifier[0].identifier).to eq('6D9DC77B-70ED-432F-ABAA-5DE8753C967C')
    end

    it 'finds identity by URI' do
      identity = subject.identity('ico://sk/42156424')

      expect(identity.general_data.uri).to eq('ico://sk/42156424')
    end

    context 'with no identifier' do
      it 'raises error' do
        expect { subject.identity(nil) }.to raise_error(sk.gov.schemas.identity.service._1_7.GetIdentityFault, 'Nesprávne vstupné parametre!')
      end
    end

    context 'with invalid identifier' do
      it 'raises error' do
        expect { subject.identity('?') }.to raise_error(sk.gov.schemas.identity.service._1_7.GetIdentityFault, 'Nastala chyba: IDENTITY_ID_FAULT')
      end
    end

    include_examples 'UPVS proxy internals', -> { subject.identity('6d9dc77b-70ed-432f-abaa-5de8753c967c') }
  end

  describe '#search' do
    it 'returns identity data' do
      identities = subject.search(corporate_body: { cin: 42156424 })

      expect(identities).not_to be_empty
      expect(identities).to all be_a sk.gov.schemas.identity.identitydata._1.IdentityData
    end

    it 'finds identity by ID' do
      identities = subject.search(ids: ['6d9dc77b-70ed-432f-abaa-5de8753c967c'])

      expect(identities.count).to eq(1)
      expect(identities.first.general_data.egov_identifier[0].identifier).to eq('6D9DC77B-70ED-432F-ABAA-5DE8753C967C')
    end

    it 'finds identity by URI' do
      identities = subject.search(uris: ['ico://sk/42156424'])

      expect(identities.count).to eq(1)
      expect(identities.first.general_data.uri).to eq('ico://sk/42156424')
    end

    it 'finds identity by EN' do
      identities = subject.search(en: 'E0000012800')

      expect(identities.count).to eq(1)
      expect(identities.first.upvs_attributes.edesk_number).to eq('E0000012800')
    end

    pending 'finds identities by type'

    it 'finds identities by e-mail' do
      identities = subject.search(email: 'test@slovensko.sk')

      expect(identities.count).to be > 0
      expect(identities.map { |identity| identity.internet_address.map(&:address) }).to all include('mailto:test@slovensko.sk')
    end

    it 'finds identity by phone' do
      identities = subject.search(phone: '+422232780700')

      expect(identities.count).to be > 0
      expect(identities.map { |identity| identity.telephone_address.map { |address| address.telephone_number.formatted_number.value }}).to all include('+422232780700')
    end

    pending 'finds identity by address'

    context 'search corporate bodies' do
      it 'finds corporate bodies by CIN' do
        identities = subject.search(corporate_body: { cin: 42156424 })

        expect(identities.count).to be > 1
        expect(identities.map { |identity| identity.id.find { |id| id.identifier_type.id == '7' }.identifier_value }).to all eq('42156424')
      end

      it 'finds corporate body by TIN' do
        identities = subject.search(corporate_body: { tin: 2022556677 })

        expect(identities.count).to eq(1)
        expect(identities.first.id.find { |id| id.identifier_type.id == '8' }.identifier_value).to eq('2022556677')
      end

      it 'finds corporate body by name' do
        identities = subject.search(corporate_body: { name: 'UPVS' })

        expect(identities.count).to eq(1)
        expect(identities.first.corporate_body.corporate_body_name).to eq('UPVS')
      end

      it 'finds corporate bodies by name prefix' do
        identities = subject.search(corporate_body: { name: 'Národná agentúra' }, match: 'prefix')

        expect(identities.count).to be > 1
        expect(identities.map { |identity| identity.corporate_body.corporate_body_name }).to all start_with('Národná agentúra')
      end

      pending 'finds corporate bodies by legal form'
    end

    context 'search natural persons' do
      pending 'finds natural persons by type'

      it 'finds natural persons by given name' do
        identities = subject.search(natural_person: { given_name: 'Janko' })

        expect(identities.count).to be > 1
        expect(identities.map { |identity| identity.physical_person.person_name.given_name.to_a }).to all include('Janko')
      end

      it 'finds natural persons by given name prefix' do
        identities = subject.search(natural_person: { given_name: 'J' }, match: 'prefix')

        expect(identities.count).to be > 1
        expect(identities.map { |identity| identity.physical_person.person_name.given_name.to_a }).to all include(start_with('J'))
      end

      it 'finds natural persons by family name' do
        identities = subject.search(natural_person: { family_name: 'Hraško' })

        expect(identities.count).to be > 1
        expect(identities.map { |identity| identity.physical_person.person_name.family_name.map(&:value) }).to all include('Hraško')
      end

      it 'finds natural persons by family name prefix' do
        identities = subject.search(natural_person: { family_name: 'H' }, match: 'prefix')

        expect(identities.count).to be > 1
        expect(identities.map { |identity| identity.physical_person.person_name.family_name.map(&:value) }).to all include(start_with('H'))
      end

      pending 'finds natural persons by date of birth'
      pending 'finds natural persons by place of birth'
    end

    context 'with pagination' do
      it 'uses given page number' do
        expect(upvs.iam).to receive(:get_edesk_info2).with(anything).and_wrap_original do |method, request|
          expect(request.paging.start_index).to eq(21)
          expect(request.paging.num_records_per_page).to eq(20)

          method.call(request).tap do |response|
            expect(response.paging.start_index).to eq(21)
            expect(response.paging.num_records).to eq(1)
            expect(response.paging.num_records_per_page).to eq(0)
          end
        end

        subject.search(en: 'E0000012800', page: 2)
      end

      it 'uses given per page number' do
        expect(upvs.iam).to receive(:get_edesk_info2).with(anything).and_wrap_original do |method, request|
          expect(request.paging.start_index).to eq(1)
          expect(request.paging.num_records_per_page).to eq(40)

          method.call(request).tap do |response|
            expect(response.paging.start_index).to eq(1)
            expect(response.paging.num_records).to eq(1)
            expect(response.paging.num_records_per_page).to eq(0)
          end
        end

        subject.search(en: 'E0000012800', per_page: 40)
      end
    end

    context 'with no query' do
      it 'raises error' do
        expect { subject.search }.to raise_error(sk.gov.schemas.identity.service._1_7.GetEdeskInfo2Fault, 'Vstupné dáta potrebné na vyhľadanie používateľov nie sú vyplnené!')
      end
    end

    context 'with invalid query' do
      it 'raises error' do
        expect { subject.search(corporate_body: { cin: 0 }, natural_person: { given_name: '?' }) }.to raise_error(sk.gov.schemas.identity.service._1_7.GetEdeskInfo2Fault, 'Chybný vstup, kombinácia PhysicalPerson a CorporateBody')
      end
    end

    include_examples 'UPVS proxy internals', -> { subject.search(en: 'E0000012800') }
  end
end
