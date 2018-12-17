class CreateFormTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :form_templates do |t|
      t.string :identifier, null: false
      t.integer :version_major, null: false
      t.integer :version_minor, null: false

      t.timestamps
    end

    add_index :form_templates, [:identifier, :version_major, :version_minor], unique: true, name: 'index_form_templates_on_identifier_and_version'
  end
end
