require 'rails_helper'

RSpec.describe IamRepository, :upvs do
  let(:properties) { UpvsEnvironment.properties(assertion: nil) }
  let(:upvs) { UpvsProxy.new(properties) }

  subject { described_class.new(upvs) }

  before(:example) { cache_java_object_proxy!(upvs.iam) }

  describe '#identity' do
    it 'returns identity data' do
      identity = subject.identity('6d9dc77b-70ed-432f-abaa-5de8753c967c')

      expect(identity).to be_a sk.gov.schemas.identity.identitydata._1.IdentityData
    end

    it 'gets identity by ID' do
      identity = subject.identity('6d9dc77b-70ed-432f-abaa-5de8753c967c')

      expect(identity.general_data.egov_identifier[0].identifier).to eq('6D9DC77B-70ED-432F-ABAA-5DE8753C967C')
    end

    it 'gets identity by URI' do
      identity = subject.identity('ico://sk/42156424')

      expect(identity.general_data.uri).to eq('ico://sk/42156424')
    end
  end
end
