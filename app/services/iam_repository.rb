class IamRepository
  def initialize(proxy)
    @upvs = proxy
  end

  def identity(id)
    request = factory.create_get_identity_request
    request.identity_id = id

    @upvs.iam.get_identity(request).identity_data
  end

  private

  mattr_reader :factory, default: sk.gov.schemas.identity.service._1.ObjectFactory.new
end
