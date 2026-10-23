class AddClosedAtToJobPostings < ActiveRecord::Migration[8.1]
  def change
    add_column :job_postings, :closed_at, :datetime
  end
end
