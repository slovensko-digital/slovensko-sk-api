module Upvs
  def self.env
    @env ||= ActiveSupport::StringInquirer.new(ENV.fetch('UPVS_ENV', 'dev'))
  end
end
