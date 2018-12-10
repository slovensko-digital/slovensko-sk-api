class CreateFormTemplateRelatedDocuments < ActiveRecord::Migration[5.2]
  def change
    create_table :form_template_related_documents do |t|
      t.references :form_template, null: false
      t.string :data, null: false
      t.string :language, null: false
      t.string :document_type, null: false

      t.timestamps
    end

    add_index :form_template_related_documents, [:form_template_id, :language, :document_type], unique: true, name: 'index_related_documents_on_template_id_and_language_and_type'
  end
end
