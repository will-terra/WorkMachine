class AddAiPlanToSettings < ActiveRecord::Migration[8.1]
  def change
    # New installations start on the free models; one that already exists keeps the paid model
    # it was using.
    add_column :settings, :ai_plan, :string, null: false, default: "free"
    up_only { execute "UPDATE settings SET ai_plan = 'paid'" }
  end
end
