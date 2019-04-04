# run all examples with UPVS SSO support enabled by default

RSpec.configure do |config|
  unless (config.inclusion_filter.rules.keys + config.exclusion_filter.rules.keys).include?(:sso)
    config.filter_run_excluding sso: false
  end
end
