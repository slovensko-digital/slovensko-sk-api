# TODO replace version_major/version_minor with single version field

# == Schema Information
#
# Table name: form_templates
#
#  id            :bigint           not null, primary key
#  identifier    :string           not null
#  version_major :integer          not null
#  version_minor :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_form_templates_on_identifier_and_version  (identifier,version_major,version_minor) UNIQUE
#
class FormTemplate < ApplicationRecord
  # TODO remove class_name once FormTemplateRelatedDocument is renamed just to RelatedDocument
  has_many :related_documents, class_name: "FormTemplateRelatedDocument"

  # TODO remove but consider moving #version_major and #version_minor here as #version string
  def version
    "#{version_major}.#{version_minor}"
  end

  # TODO rename to just schema: "xsd_schema" reads "XML schema definition schema" which is weird
  def xsd_schema
    related_document("CLS_F_XSD_EDOC")
  end

  def related_document(type)
    related_documents.where(document_type: type).where("lower(language) = 'sk'").first&.data
  end
end
