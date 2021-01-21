RSpec.configure do |config|
  config.before(:example, type: :request) do |example|
    if example.description.start_with?('responds with 404', 'responds with 500')
      allow(Rails.application).to receive(:env_config).and_wrap_original do |m|
        m.call.merge(
          'action_dispatch.show_exceptions' => true,
          'action_dispatch.show_detailed_exceptions' => false,
        )
      end
    end
  end
end
