# TODO add annotate gem
# TODO replace version_major/version_minor with single version field

class FormTemplate < ApplicationRecord
  # TODO remove class_name once FormTemplateRelatedDocument is renamed just to RelatedDocument
  has_many :related_documents, class_name: 'FormTemplateRelatedDocument'

  # TODO remove but consider moving #version_major and #version_minor here as #version string
  def version
    "#{version_major}.#{version_minor}"
  end

  # TODO rename to just schema: "xsd_schema" reads "XML schema definition schema" which is weird
  def xsd_schema
    related_documents.where(document_type: 'CLS_F_XSD_EDOC').where("lower(language) = 'sk'")&.first&.data
  end
end
