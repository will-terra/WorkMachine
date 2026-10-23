require "rails_helper"

# Contatos and Vagas meet: a job or an application at a company where you know someone shows who,
# with a referral request already filled in.
RSpec.describe "Contacts at the company" do
  before { sign_in }

  let!(:contact) { create(:contact, name: "Juliana Prado", headline: "Talent Acquisition", company: "Nimbus Labs") }
  let!(:referral) do
    create(:message_template, name: "Pedido de indicação (PT)", body: "Oi, {{nome}}! Vi a vaga de {{cargo}} na {{empresa}}. Você me indicaria?")
  end

  it "shows who you know at the company of a job and asks for a referral" do
    posting = create(:job_posting, title: "Rails Engineer", company: "Nimbus Labs Inc.")
    create(:job_posting, title: "Other job", company: "Globex")

    get job_postings_path
    expect(response.body).to include("1 contato").once

    get job_posting_path(posting)
    expect(response.body).to include("Você conhece 1 pessoa na Nimbus Labs Inc.", "Juliana Prado", "Talent Acquisition")

    link = Nokogiri::HTML(response.body).at_css("a:contains('Pedir indicação')")["href"]
    expect(link).to include("job_posting_id=#{posting.id}", "nome=Juliana", "template_id=#{referral.id}", "#message_template_#{referral.id}")

    get link
    expect(response.body).to include("Oi, Juliana! Vi a vaga de Rails Engineer na Nimbus Labs Inc.. Você me indicaria?")
  end

  it "shows the contact on the application card and fills the request from the application" do
    application = create(:job_application, company: "nimbus labs", role: "Backend Engineer", status: "applied")

    get job_applications_path(view: "board")
    expect(response.body).to include("Você conhece 1 pessoa na nimbus labs")

    link = Nokogiri::HTML(response.body).at_css("a:contains('Pedir indicação')")["href"]
    expect(link).to include("job_application_id=#{application.id}")

    get link
    expect(response.body).to include("Oi, Juliana! Vi a vaga de Backend Engineer na nimbus labs. Você me indicaria?")
  end

  it "shows nothing when you know nobody there" do
    posting = create(:job_posting, company: "Globex")

    get job_posting_path(posting)

    expect(response.body).not_to include("Pedir indicação")
  end

  it "prefers the referral template in the interface language" do
    english = create(:message_template, name: "Referral request (EN)", language: "en", body: "Hi {{nome}}!")

    expect(MessageTemplate.referral).to eq(referral)
    expect(I18n.with_locale(:en) { MessageTemplate.referral }).to eq(english)
  end
end
