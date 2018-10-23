class UpvsService
  include ForceTimeout
  include UnwrapErrors

  attr_reader :upvs

  def initialize(properties)
    # TODO cache Upvs objects here - consider Java vs Ruby cache
    @upvs = digital.slovensko.upvs.UpvsProxy.new(properties)
  end

  private :upvs
end
