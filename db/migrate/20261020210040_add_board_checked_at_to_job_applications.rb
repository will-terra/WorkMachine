class AddBoardCheckedAtToJobApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :job_applications, :board_checked_at, :datetime
  end
end
