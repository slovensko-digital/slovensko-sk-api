require 'rails_helper'

RSpec.describe UpvsEnvironment do
  subject { described_class }

  pending '.upvs_properties'

  describe '.upvs_proxy' do
    before(:example) { allow(UpvsProxy).to receive(:new).and_wrap_original { Object.new }}

    before(:example) { UpvsEnvironment.upvs_proxy_cache.invalidate_all }

    it 'returns same proxy object in the first 120 minutes' do
      travel_to Time.now

      u1 = subject.upvs_proxy(sub: 'test')

      travel_to 120.minutes.from_now - 0.1.seconds

      u2 = subject.upvs_proxy(sub: 'test')

      expect(u1).to equal(u2)
    end

    it 'returns new proxy object on or after 120 minutes' do
      travel_to Time.now

      u1 = subject.upvs_proxy(sub: 'test')

      travel_to 120.minutes.from_now

      u2 = subject.upvs_proxy(sub: 'test')

      expect(u1).not_to equal(u2)
    end

    pending 'with OBO identifier'

    context 'with OBO assertion' do
      let(:assertion) { file_fixture('oam/sso_response_success_assertion.xml').read.strip }

      it 'returns same proxy object in the first 120 minutes' do
        travel_to Time.now

        u1 = subject.upvs_proxy(sub: 'test', obo: assertion)

        travel_to 120.minutes.from_now - 0.1.seconds

        u2 = subject.upvs_proxy(sub: 'test', obo: assertion)

        expect(u1).to equal(u2)
      end

      it 'returns new proxy object on or after 120 minutes' do
        travel_to Time.now

        u1 = subject.upvs_proxy(sub: 'test', obo: assertion)

        travel_to 120.minutes.from_now

        u2 = subject.upvs_proxy(sub: 'test', obo: assertion)

        expect(u1).not_to equal(u2)
      end
    end
  end

  pending '.obo_support?'

  pending '.sso_support?'

  pending '.sso_settings'

  pending '.sso_proxy_subject'
end
