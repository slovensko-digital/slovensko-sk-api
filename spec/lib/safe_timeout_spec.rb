require 'rails_helper'

RSpec.describe SafeTimeout do
  subject { described_class }

  describe '.timeout' do
    it 'returns block evaluation' do
      expect(subject.timeout(1_000) { 0 }).to eq(0)
    end

    it 'raises NullPointerException on missing block' do
      expect { subject.timeout(1) }.to raise_error(java.lang.NullPointerException)
    end

    it 'raises IllegalArgumentException on non-positive timeout' do
      expect { subject.timeout(0) {} }.to raise_error(java.lang.IllegalArgumentException)
    end

    it 'raises TimeoutException on timeout' do
      expect { subject.timeout(0.000_001) { sleep 1 }}.to raise_error(java.util.concurrent.TimeoutException)
    end

    it 'raises custom error on timeout' do
      expect { subject.timeout(0.000_001, StandardError) { sleep 1 }}.to raise_error(StandardError) { |e| expect(e.cause).to be_a(java.util.concurrent.TimeoutException) }
    end

    it 'raises ExecutionError on block evaluation critical Java failure' do
      expect { subject.timeout(1_000) { raise java.lang.Error.new }}.to raise_error(com.google.common.util.concurrent.ExecutionError) { |e| expect(e.cause).to be_a(java.lang.Error) }
    end

    it 'raises ExecutionException on block evaluation checked Java failure' do
      expect { subject.timeout(1_000) { raise java.lang.Exception.new }}.to raise_error(java.util.concurrent.ExecutionException) { |e| expect(e.cause).to be_a(java.lang.Exception) }
    end

    it 'raises UncheckedExecutionException on block evaluation unchecked Java failure' do
      expect { subject.timeout(1_000) { raise java.lang.RuntimeException.new }}.to raise_error(com.google.common.util.concurrent.UncheckedExecutionException) { |e| expect(e.cause).to be_a(java.lang.RuntimeException) }
    end

    it 'raises UncheckedExecutionException on block evaluation Ruby failure' do
      expect { subject.timeout(1_000) { raise Exception }}.to raise_error(com.google.common.util.concurrent.UncheckedExecutionException) { |e| expect(e.cause).to be_a(org.jruby.exceptions.RaiseException) }
    end
  end
end
