# TODO this is too long, rename just to RelatedDocument as is sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.RelatedDocument
class FormTemplateRelatedDocument < ApplicationRecord
  belongs_to :form_template

  # TODO rename document_type to type
  # TODO rename data to content
end
