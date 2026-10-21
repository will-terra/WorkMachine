class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.string :name
      t.string :headline
      t.string :location
      t.string :time_zone, null: false, default: "Brasilia"
      t.string :languages
      t.string :linkedin_url
      t.string :github_url
      t.string :portfolio_url

      t.string :primary_area
      t.string :plan_b_area
      t.json :target_titles, null: false, default: []
      t.json :target_titles_en, null: false, default: []
      t.string :seniority, null: false, default: "mid"
      t.integer :years_experience
      t.json :work_modes, null: false, default: [ "remote" ]
      t.json :regions, null: false, default: %w[brazil latam worldwide]
      t.integer :salary_brl_min
      t.integer :salary_brl_max
      t.integer :salary_usd_min
      t.integer :salary_usd_max

      t.json :skills, null: false, default: []
      t.json :avoid_terms, null: false, default: []
      t.json :search_terms, null: false, default: []
      t.json :plan_b_terms, null: false, default: []
      t.json :domains, null: false, default: []
      t.json :search_overrides, null: false, default: {}

      t.text :ai_profile
      t.text :cv_text
      t.json :dream_posting_ids, null: false, default: []

      t.timestamps
    end
  end
end
