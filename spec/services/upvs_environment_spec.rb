require 'rails_helper'

RSpec.describe UpvsEnvironment do
  subject { described_class }

  describe '.upvs_proxy' do
    before(:example) { UpvsEnvironment.upvs_proxy_cache.clean_up }

    before(:example) { travel_to '2018-11-28T20:26:16Z' }

    after(:example) { travel_back }

    context 'with assertion' do
      let(:assertion) { file_fixture('oam/sso_response_success_assertion.xml').read.strip }

      it 'returns same proxy object in the first 120 minutes' do
        u1 = subject.upvs_proxy(assertion: assertion)

        travel_to Time.now + 120.minutes - 0.1.seconds

        u2 = subject.upvs_proxy(assertion: assertion)

        expect(u1).to equal(u2)
      end

      it 'returns new proxy object on or after 120 minutes' do
        u1 = subject.upvs_proxy(assertion: assertion)

        travel_to Time.now + 120.minutes

        u2 = subject.upvs_proxy(assertion: assertion)

        expect(u1).not_to equal(u2)
      end
    end

    context 'with TA key' do
      it 'returns same proxy object in the first 120 minutes' do
        u1 = subject.upvs_proxy(assertion: nil)

        travel_to Time.now + 120.minutes - 0.1.seconds

        u2 = subject.upvs_proxy(assertion: nil)

        expect(u1).to equal(u2)
      end

      it 'returns new proxy object on or after 120 minutes' do
        u1 = subject.upvs_proxy(assertion: nil)

        travel_to Time.now + 120.minutes

        u2 = subject.upvs_proxy(assertion: nil)

        expect(u1).not_to equal(u2)
      end
    end
  end
end
