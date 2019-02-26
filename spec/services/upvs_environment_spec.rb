require 'rails_helper'

RSpec.describe UpvsEnvironment do
  subject { described_class }

  describe '.upvs_proxy' do
    context 'with assertion' do


      it 'creates proxy object' do

      end


    end

    context 'without assertion' do
      before(:example) { travel_to '2018-11-28T20:26:16Z' }

      after(:example) { travel_back }

      it 'returns upvs proxy from cache' do
        u1 = subject.upvs_proxy(assertion: nil)
        u2 = subject.upvs_proxy(assertion: nil)

        expect(u1).to equal(u2)
      end


    end
  end
end
