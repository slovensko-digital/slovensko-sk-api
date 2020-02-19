module IamObjects
  def iam_get_identity_response(file)
    java_object_from_xml(sk.gov.schemas.identity.service._1.GetIdentityResponse, file_fixture(file).read)
  end

  def iam_get_identity_fault(file)
    java_object_from_xml(sk.gov.schemas.identity.service._1_7.GetIdentityFault, file_fixture(file).read)
  end
end

RSpec.configure do |config|
  config.include IamObjects
end
