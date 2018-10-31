class UpvsProxy
  def initialize(properties)
    # TODO cache Upvs objects here - consider Java vs Ruby cache
    @upvs = digital.slovensko.upvs.UpvsProxy.new(properties)
  end
end
