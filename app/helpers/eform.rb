module Eform
  SERVICES = sk.gov.schemas.servicebus.service._1.ServiceClassEnum

  @object_factory = sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.ObjectFactory.new

  def self.object_factory
    @object_factory
  end

  def self.build_form_template_id(form_template)
    form_template_id = @object_factory.create_form_template_id
    form_template_id.identifier = @object_factory.create_form_template_id_identifier(form_template.identifier)

    form_version = @object_factory.create_eform_version
    form_version.major = form_template.version_major
    form_version.minor = form_template.version_minor

    form_template_id.version = @object_factory.create_form_template_id_version(form_version)
    form_template_id
  end
end
