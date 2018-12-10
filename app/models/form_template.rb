class FormTemplate < ApplicationRecord
  has_many :related_documents, class_name: 'FormTemplateRelatedDocument'
end
