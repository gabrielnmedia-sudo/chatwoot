class CreatePipelineStages < ActiveRecord::Migration[7.0]
  def change
    create_table :pipeline_stages do |t|
      t.string :name, index: true
      t.integer :position, index: true
      t.string :color
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
