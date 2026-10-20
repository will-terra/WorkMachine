require "rails_helper"

RSpec.describe "API v1 job postings" do
  let(:token) { "token-de-teste-123" }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }
  let(:payload) do
    { job_posting: { title: "Desenvolvedor Ruby on Rails Pleno", company: "Acme", url: "https://br.linkedin.com/jobs/view/4012345678/?trk=x",
                     description: "Rails, Hotwire e PostgreSQL", location_text: "Brasil (Remoto)" } }
  end

  around do |example|
    ENV["WORKMACHINE_API_TOKEN"] = token
    example.run
  ensure
    ENV.delete("WORKMACHINE_API_TOKEN")
  end

  it "creates a scored posting from the extension" do
    post api_v1_job_postings_path, params: payload, headers:, as: :json

    expect(response).to have_http_status(:created)
    body = response.parsed_body
    expect(body).to include("title" => "Desenvolvedor Ruby on Rails Pleno", "duplicate" => false, "remote_scope" => "Brasil")
    expect(body["score"]).to be >= 50
    expect(body["app_url"]).to end_with("/vagas/#{body["id"]}")
    expect(JobPosting.last).to have_attributes(source: "extension", url: "https://www.linkedin.com/jobs/view/4012345678")
  end

  it "answers 200 for a duplicate and can create the application" do
    post api_v1_job_postings_path, params: payload, headers:, as: :json

    expect {
      post api_v1_job_postings_path, params: payload.merge(create_application: true), headers:, as: :json
    }.to change(JobApplication, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("duplicate" => true, "job_application_id" => JobApplication.last.id)
    expect(JobPosting.last).to be_triage_saved
  end

  it "rejects invalid data" do
    post api_v1_job_postings_path, params: { job_posting: { title: "", url: "" } }, headers:, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to be_present
  end

  it "rejects a wrong or missing token" do
    post api_v1_job_postings_path, params: payload, headers: { "Authorization" => "Bearer errado" }, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body["error"]).to include("Token inválido")

    post api_v1_job_postings_path, params: payload, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(JobPosting.count).to eq(0)
  end

  it "explains when the server has no token configured" do
    ENV.delete("WORKMACHINE_API_TOKEN")

    get api_v1_ping_path, headers: headers

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body["error"]).to include("WORKMACHINE_API_TOKEN")
  end

  it "answers the ping with a valid token" do
    get api_v1_ping_path, headers: headers

    expect(response.parsed_body).to eq("ok" => true, "app" => "WorkMachine")
  end
end
