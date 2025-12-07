class AddSettingsToDataImports < ActiveRecord::Migration[7.0]
  def change
    add_column :data_imports, :settings, :jsonb, default: {}
  end
end
