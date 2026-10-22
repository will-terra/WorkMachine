require "rails_helper"

# Every screen in English: a missing key raises (raise_on_missing_translations) and any Portuguese
# left in the text, placeholders, titles or labels of the page fails here. The data is in English.
RSpec.describe "English interface" do
  PORTUGUESE = /[ãõçáéíóúâêôà]|\b(?:não|você|para|com|sem|das|dos|nas|nos|uma|Salvar|Editar|Vagas|Buscar|Nenhum|Nenhuma|Abrir|Ver|Todas|Todos)\b/i
  # Names of languages, sources and companies, and Portuguese search terms, on purpose.
  ALLOWED = /\Ahttps?:\/\/|\A(?:Português|backend-br\/vagas|frontendbr\/vagas)\z|Sólides|“Trabalhe conosco”|“Vagas”/

  let(:headers) { { "Accept-Language" => "en-US,en;q=0.9" } }

  def portuguese_in(html)
    document = Nokogiri::HTML(html)
    document.css("script, style, template, [lang='pt-BR'], [translate='no'], [data-user-content]").each(&:remove)
    texts = document.xpath("//body//text()").map(&:text)
    texts += document.css("[placeholder], [title], [aria-label], [alt]").flat_map { |node| [ node["placeholder"], node["title"], node["aria-label"], node["alt"] ] }
    texts += document.css("input[type=submit], input[type=button]").map { it["value"] }
    texts.compact.map(&:squish).compact_blank.reject { it.match?(ALLOWED) }.select { it.gsub(%r{\S*\.(?:com|io|co|org|br)\b\S*}, "").match?(PORTUGUESE) }.uniq
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
      Profile.current.update!(skills: [ { "name" => "Rails", "level" => "essential", "synonyms" => [ "Ruby on Rails" ] }, { "name" => "React", "level" => "extra" } ],
                              domains: [ "fintech" ], languages: "English")
      # The ready-made routines are copied in the language of the first visit.
      I18n.with_locale(:en) { Routine.current }
    end

    # Grows with the translation: every screen goes in this list once it is translated.
    it "shows the translated screens in English" do
      application = JobApplication.last
      posting = JobPosting.last
      [
        job_postings_path, job_postings_path(selected: posting.id), job_posting_path(posting), new_job_posting_path,
        job_applications_path(view: "board"), job_applications_path(view: "table"), new_job_application_path, edit_job_application_path(application),
        root_path, metrics_path, radar_path, message_templates_path, message_templates_path(job_application_id: application.id),
        new_message_template_path, edit_message_template_path(MessageTemplate.last), routine_path,
        contacts_path, new_contact_path, edit_contact_path(Contact.last),
        target_companies_path, new_target_company_path, edit_target_company_path(TargetCompany.last),
        settings_routines_path, new_settings_routine_path, edit_settings_routine_path(Routine.current.last), profile_path,
        settings_path, onboarding_path
      ].each { visit_in_english(it) }
    end
  end
end
