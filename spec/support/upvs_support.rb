module UpvsSupport
  delegate :sso_support?, to: UpvsEnvironment
  delegate :obo_support?, to: UpvsEnvironment
end

RSpec.configure do |config|
  # enable UPVS helpers in examples
  config.include UpvsSupport

  # enable UPVS helpers in example groups
  config.extend UpvsSupport

  def config.inclusion_or_exclusion_filter?(tag)
    inclusion_filter.rules.key?(tag) || exclusion_filter.rules.key?(tag)
  end

  # skip all examples related to UPVS STS by default
  config.filter_run_excluding(sts: true) unless config.inclusion_or_exclusion_filter?(:sts)

  # skip all examples related to NASES UAT by default
  config.filter_run_excluding(uat: true) unless config.inclusion_or_exclusion_filter?(:uat)

  warn 'WARNING: Please consider running examples in UPVS FIX environment' unless Upvs.env.fix?
  abort 'ERROR: Unable to run examples in UPVS PROD environment' if Upvs.env.prod?
end
