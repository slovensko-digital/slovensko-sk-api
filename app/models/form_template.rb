class FormTemplate < ApplicationRecord
  has_many :related_documents, class_name: 'FormTemplateRelatedDocument'

  def xsd_schema
    related_documents.where(document_type: 'CLS_F_XSD_EDOC').where("lower(language) = 'sk'")&.first.data
  end
end
