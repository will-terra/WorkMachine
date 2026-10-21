class AddCvDraftToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :cv_draft, :json
    add_column :profiles, :cv_draft_status, :string
    add_column :profiles, :cv_draft_error, :text
  end
end
