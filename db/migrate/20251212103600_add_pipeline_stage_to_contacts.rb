class AddPipelineStageToContacts < ActiveRecord::Migration[7.0]
  def change
    add_reference :contacts, :pipeline_stage, null: true, foreign_key: true
  end
end
