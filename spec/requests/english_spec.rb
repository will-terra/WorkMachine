require "rails_helper"

# Every screen in English: a missing key raises (raise_on_missing_translations) and any Portuguese
# left in the text, placeholders, titles or labels of the page fails here. The data is in English.
RSpec.describe "English interface" do
  PORTUGUESE = /[ãõçáéíóúâêôà]|\b(?:não|você|para|com|sem|das|dos|nas|nos|uma|Salvar|Editar|Vagas|Buscar|Nenhum|Nenhuma|Abrir|Ver|Todas|Todos)\b/i
  # Names of languages are written in their own language on purpose.
  ALLOWED = [ "Português" ].freeze

  let(:headers) { { "Accept-Language" => "en-US,en;q=0.9" } }

  def portuguese_in(html)
    document = Nokogiri::HTML(html)
    document.css("script, style, template, [lang='pt-BR'], [data-user-content]").each(&:remove)
    texts = document.xpath("//body//text()").map(&:text)
    texts += document.css("[placeholder], [title], [aria-label], [alt]").flat_map { |node| [ node["placeholder"], node["title"], node["aria-label"], node["alt"] ] }
    texts += document.css("input[type=submit], input[type=button]").map { it["value"] }
    texts.compact.map(&:squish).compact_blank.reject { ALLOWED.include?(it) }.select { it.match?(PORTUGUESE) }.uniq
  end

  def visit_in_english(path)
    get path, headers: headers
    expect(response).to have_http_status(:ok), "#{path} answered #{response.status}"
    left = portuguese_in(response.body)
    expect(left).to eq([]), "Portuguese left on #{path}: #{left.inspect}"
  end

  context "signed out" do
    it "shows the sign in and the first account screens in English" do
      visit_in_english new_setup_path
      create(:user)
      visit_in_english new_session_path
    end
  end

  context "signed in" do
    before do
      sign_in
      posting = create(:job_posting, title: "Senior Rails Engineer", company: "Acme", location_text: "Remote", salary_text: "USD 6k")
      create(:ai_artifact, job_posting: posting, content: "Good fit.")
      application = create(:job_application, company: "Globex", role: "Backend Engineer", status: "applied", applied_on: 3.days.ago.to_date,
                                             next_follow_up_on: Date.current, job_posting: posting)
      create(:application_email, job_application: application, subject: "Your application", summary: "They want an interview.", category: "interview")
      create(:contact, name: "Mary Smith", headline: "Tech Recruiter", company: "Initech")
      create(:message_template, name: "Recruiter note", language: "en", body: "Hi {{nome}}, about the {{cargo}} role at {{empresa}}.", max_chars: 200)
      create(:target_company, name: "GitLab", board_slug: "gitlab")
      create(:consultancy, name: "Example Talent", notes: "Tech recruiting.")
      SourceRun.create!(source: "remotive", status: "succeeded", fetched_count: 10, created_count: 2, finished_at: Time.current)
    end

    # Grows with the translation: every screen goes in this list once it is translated.
    it "shows the translated screens in English" do
      application = JobApplication.last
      posting = JobPosting.last
      [
        job_postings_path, job_postings_path(selected: posting.id), job_posting_path(posting), new_job_posting_path,
        job_applications_path(view: "board"), job_applications_path(view: "table"), new_job_application_path, edit_job_application_path(application)
      ].each { visit_in_english(it) }
    end
  end
end
