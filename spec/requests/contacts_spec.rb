require "rails_helper"

RSpec.describe "Contacts" do
  before { sign_in }

  it "lists, creates, updates and deletes contacts" do
    get contacts_path
    expect(response.body).to include("Nenhum contato ainda")

    get new_contact_path
    expect(response).to have_http_status(:ok)

    post contacts_path, params: { contact: { name: "Mariana", headline: "Tech Recruiter", company: "Acme", kind: "recruiter", linkedin_url: "https://www.linkedin.com/in/mariana" } }
    contact = Contact.last
    expect(response).to redirect_to(contacts_path)

    get edit_contact_path(contact)
    expect(response.body).to include("Mariana")

    patch contact_path(contact), params: { contact: { kind: "manager" } }
    expect(contact.reload).to be_manager

    get contacts_path
    expect(response.body).to include("Gestor(a)", "Tech Recruiter")

    expect { delete contact_path(contact) }.to change(Contact, :count).by(-1)
  end

  it "filters by kind and search and shows how long ago the last contact was" do
    create(:contact, name: "Mariana", company: "Acme", kind: "recruiter", last_contacted_on: 3.days.ago.to_date)
    create(:contact, name: "Paulo", company: "Globex", kind: "manager", last_contacted_on: nil)

    get contacts_path
    expect(response.body).to include("Mariana", "Paulo", "há 3 dias", "nunca")

    get contacts_path(kind: "manager")
    expect(response.body).to include("Paulo")
    expect(response.body).not_to include("Mariana")

    get contacts_path(q: "acme")
    expect(response.body).to include("Mariana")
    expect(response.body).not_to include("Paulo")

    get contacts_path(q: "ninguém")
    expect(response.body).to include("Nenhum contato com esses filtros.")
  end

  it "re-renders the forms with errors" do
    post contacts_path, params: { contact: { name: "" } }
    expect(response).to have_http_status(:unprocessable_content)

    contact = create(:contact)
    patch contact_path(contact), params: { contact: { name: "" } }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
