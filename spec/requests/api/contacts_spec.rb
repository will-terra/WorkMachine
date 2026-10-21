require "rails_helper"

RSpec.describe "API v1 contacts" do
  let(:token) { "token-de-teste-123" }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }
  let(:contact) do
    { name: "Mariana Souza", headline: "Tech Recruiter na Acme", company: "Acme", kind: "recruiter",
      linkedin_url: "https://br.linkedin.com/in/Mariana-Souza/?originalSubdomain=br" }
  end

  around do |example|
    ENV["WORKMACHINE_API_TOKEN"] = token
    example.run
  ensure
    ENV.delete("WORKMACHINE_API_TOKEN")
  end

  it "saves a contact from a LinkedIn profile" do
    post api_v1_contacts_path, params: { contact: }, headers:, as: :json

    expect(response).to have_http_status(:created)
    saved = Contact.last
    expect(saved).to have_attributes(name: "Mariana Souza", headline: "Tech Recruiter na Acme", company: "Acme",
                                     linkedin_url: "https://www.linkedin.com/in/mariana-souza")
    expect(response.parsed_body).to include("duplicate" => false, "kind_label" => "Recrutador(a)")
    expect(response.parsed_body["app_url"]).to end_with("/contatos#contact_#{saved.id}")
  end

  it "only fills blanks when the profile is saved again" do
    existing = create(:contact, name: "Mari Souza", company: nil, headline: nil, kind: "manager",
                                linkedin_url: "https://www.linkedin.com/in/mariana-souza")

    expect {
      post api_v1_contacts_path, params: { contact: }, headers:, as: :json
    }.not_to change(Contact, :count)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["duplicate"]).to be(true)
    expect(existing.reload).to have_attributes(name: "Mari Souza", kind: "manager", company: "Acme", headline: "Tech Recruiter na Acme")
  end

  it "notes the job of a hiring team member once and names the application" do
    posting = create(:job_posting, title: "Rails Engineer", url: "https://www.linkedin.com/jobs/view/123")
    application = posting.save_as_application!
    job = { title: "Rails Engineer", url: "https://www.linkedin.com/jobs/view/123/?trk=x" }

    2.times { post api_v1_contacts_path, params: { contact:, job: }, headers:, as: :json }

    expect(Contact.last.notes).to eq("Vaga: Rails Engineer — https://www.linkedin.com/jobs/view/123")
    expect(application.reload.contact_name).to eq("Mariana Souza")
  end

  it "keeps the contact name already on the application" do
    posting = create(:job_posting, url: "https://www.linkedin.com/jobs/view/123")
    application = posting.save_as_application!
    application.update!(contact_name: "Ana")

    post api_v1_contacts_path, params: { contact:, job: { url: posting.url } }, headers:, as: :json

    expect(application.reload.contact_name).to eq("Ana")
  end

  it "rejects a contact without a name" do
    post api_v1_contacts_path, params: { contact: contact.merge(name: "") }, headers:, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to be_present
  end

  it "looks a profile up by any form of its URL" do
    create(:contact, linkedin_url: "https://www.linkedin.com/in/mariana-souza")

    get lookup_api_v1_contacts_path, params: { linkedin_url: "https://www.linkedin.com/in/mariana-souza/" }, headers: headers
    expect(response.parsed_body).to include("found" => true, "name" => "Mariana Souza")

    get lookup_api_v1_contacts_path, params: { linkedin_url: "" }, headers: headers
    expect(response.parsed_body).to eq("found" => false)
  end
end
