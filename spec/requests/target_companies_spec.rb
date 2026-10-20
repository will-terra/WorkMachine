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

  it "re-renders the forms with errors" do
    post target_companies_path, params: { target_company: { name: "", ats: "lever", board_slug: "a b" } }
    expect(response).to have_http_status(:unprocessable_content)

    company = create(:target_company)
    patch target_company_path(company), params: { target_company: { board_slug: "" } }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
