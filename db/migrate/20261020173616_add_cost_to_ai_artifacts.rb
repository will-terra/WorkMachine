class AddCostToAiArtifacts < ActiveRecord::Migration[8.1]
  def change
    add_column :ai_artifacts, :cache_write_tokens, :integer
    add_column :ai_artifacts, :cache_read_tokens, :integer
    add_column :ai_artifacts, :cost_usd, :decimal, precision: 10, scale: 6
  end
end
