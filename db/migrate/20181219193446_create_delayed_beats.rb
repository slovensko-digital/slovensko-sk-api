class CreateDelayedBeats < ActiveRecord::Migration[5.2]
  def change
    create_table :delayed_beats do |t|
      t.string :job_class, index: { unique: true }, null: false

      t.timestamps
    end
  end
end
