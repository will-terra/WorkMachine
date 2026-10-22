require "rails_helper"

RSpec.describe "Message templates" do
  before { sign_in }

  let!(:template) { create(:message_template, body: "Oi, {{nome}}! Vaga de {{cargo}} na {{empresa}}.", max_chars: 200) }

  it "lists the templates with the placeholders visible" do
    get message_templates_path

    expect(response.body).to include("Oi, {{nome}}! Vaga de {{cargo}} na {{empresa}}.", "/ 200 caracteres")
  end

  it "fills the placeholders from an application" do
    application = create(:job_application, company: "Acme", role: "Rails Dev", contact_name: "Mariana Souza")

    get message_templates_path(job_application_id: application.id)

    expect(response.body).to include("Oi, Mariana! Vaga de Rails Dev na Acme.")
  end

  it "fills the placeholders from a posting" do
    posting = create(:job_posting, company: "Globex", title: "Ruby Engineer")

    get message_templates_path(job_posting_id: posting.id, nome: "Ana")

    expect(response.body).to include("Oi, Ana! Vaga de Ruby Engineer na Globex.")
  end

  it "fills the name from a contact" do
    contact = create(:contact, name: "João Pedro", company: "Initech")

    get message_templates_path(contact_id: contact.id)

    expect(response.body).to include("Oi, João! Vaga de {{cargo}} na Initech.")
  end

  it "opens the template that fits the contact and fills from an application" do
    note = create(:message_template, name: "Conexão com recrutador (PT)", body: "Oi, {{nome}}! Sou {{meu_resumo}}.")
    contact = create(:contact, name: "Ana", kind: "recruiter")
    create(:job_application, company: "Acme", role: "Rails Dev", status: "applied")

    get message_templates_path(contact_id: contact.id)

    expect(response.body).to include('<h2 class="text-2xl" data-message-target="name">Conexão com recrutador (PT)</h2>', "Acme · Rails Dev", 'data-cargo="Rails Dev"')
    expect(response.body).to include('text-accent-text">Ana<', %(id="message_template_#{note.id}" aria-selected="true"))
  end

  it "creates, edits and deletes templates" do
    get new_message_template_path
    expect(response).to have_http_status(:ok)

    post message_templates_path, params: { message_template: { name: "Novo", language: "en", body: "Hi {{nome}}" } }
    expect(response).to redirect_to(message_templates_path)

    get edit_message_template_path(template)
    expect(response).to have_http_status(:ok)

    patch message_template_path(template), params: { message_template: { body: "Olá {{nome}}" } }
    expect(template.reload.body).to eq("Olá {{nome}}")

    expect { delete message_template_path(template) }.to change(MessageTemplate, :count).by(-1)
  end

  it "re-renders the forms with errors" do
    post message_templates_path, params: { message_template: { name: "", body: "" } }
    expect(response).to have_http_status(:unprocessable_content)

    patch message_template_path(template), params: { message_template: { body: "" } }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
