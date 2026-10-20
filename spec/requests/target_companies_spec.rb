require "rails_helper"

RSpec.describe "Target companies" do
  before { sign_in }

  it "lists, adds, edits and removes companies" do
    create(:target_company, name: "GitLab", example: true)

    get target_companies_path
    expect(response.body).to include("GitLab", "exemplo")

    get new_target_company_path
    expect(response).to have_http_status(:ok)

    post target_companies_path, params: { target_company: { name: "Kit", ats: "ashby", board_slug: "kit", active: "1" } }
    company = TargetCompany.find_by!(board_slug: "kit")
    expect(response).to redirect_to(target_companies_path)

    get edit_target_company_path(company)
    expect(response).to have_http_status(:ok)

    patch target_company_path(company), params: { target_company: { active: "0" } }
    expect(company.reload).not_to be_active

    expect { delete target_company_path(company) }.to change(TargetCompany, :count).by(-1)
  end

  it "lists discovered suggestions and activates or dismisses them" do
    posting = create(:job_posting, title: "Rails Engineer na Globex")
    suggestion = create(:target_company, name: "Globex", board_slug: "globex", active: false, discovered_at: Time.current, discovered_from: posting)
    other = create(:target_company, name: "Initech", board_slug: "initech", active: false, discovered_at: Time.current)

    get target_companies_path
    expect(response.body).to include("Sugestões encontradas nas vagas", "Rails Engineer na Globex")

    post activate_target_company_path(suggestion)
    expect(suggestion.reload).to be_active

    post dismiss_target_company_path(other)
    expect(other.reload).to have_attributes(active: false, discovered_at: nil)
    expect(TargetCompany.suggested).to be_empty

    get target_companies_path
    expect(response.body).to include("descoberta")
  end

  it "shows how many postings each board brought and how many were saved" do
    create(:target_company, name: "GitLab", ats: "greenhouse", board_slug: "gitlab")
    create(:job_posting, source: "greenhouse", raw: { "board" => "gitlab" }, triage: "saved")
    create(:job_posting, source: "greenhouse", raw: { "board" => "gitlab" }, triage: "dismissed", auto_dismissed_reason: "só Europa")
    create(:job_posting, source: "greenhouse", raw: { "board" => "gitlab" })

    get target_companies_path

    expect(response.body).to include("3 · ", "1 salvas", "1 descartadas auto.")
    expect(TargetCompany.posting_stats[%w[greenhouse gitlab]]).to eq(total: 3, saved: 1, auto_dismissed: 1)
  end

  it "re-renders the forms with errors" do
    post target_companies_path, params: { target_company: { name: "", ats: "lever", board_slug: "a b" } }
    expect(response).to have_http_status(:unprocessable_content)

    company = create(:target_company)
    patch target_company_path(company), params: { target_company: { board_slug: "" } }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
