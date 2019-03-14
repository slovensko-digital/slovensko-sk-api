class UpvsProxy < SimpleDelegator
  def initialize(properties)
    super digital.slovensko.upvs.UpvsProxy.new(properties)
  end
end
