class AddDiscoveredAtToTargetCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :target_companies, :discovered_at, :datetime
    add_reference :target_companies, :discovered_from, foreign_key: { to_table: :job_postings, on_delete: :nullify }
  end
end
