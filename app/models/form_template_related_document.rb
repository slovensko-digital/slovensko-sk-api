# TODO this is too long, rename just to RelatedDocument as is sk.gov.schemas.servicebusserviceprovider.ness.eformprovider._1.RelatedDocument
# == Schema Information
#
# Table name: form_template_related_documents
#
#  id               :bigint           not null, primary key
#  data             :string           not null
#  document_type    :string           not null
#  language         :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  form_template_id :bigint           not null
#
# Indexes
#
#  index_form_template_related_documents_on_form_template_id     (form_template_id)
#  index_related_documents_on_template_id_and_language_and_type  (form_template_id,language,document_type) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (form_template_id => form_templates.id)
#
class FormTemplateRelatedDocument < ApplicationRecord
  belongs_to :form_template

  # TODO rename document_type to type
  # TODO rename data to content
end
