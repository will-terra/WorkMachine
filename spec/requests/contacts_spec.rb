require "rails_helper"

RSpec.describe "Contacts" do
  before { sign_in }

  it "lists, creates, updates and deletes contacts" do
    get contacts_path
    expect(response.body).to include("Nenhum contato ainda")

    get new_contact_path
    expect(response).to have_http_status(:ok)

    post contacts_path, params: { contact: { name: "Mariana", company: "Acme", kind: "recruiter", linkedin_url: "https://www.linkedin.com/in/mariana" } }
    contact = Contact.last
    expect(response).to redirect_to(contacts_path)

    get edit_contact_path(contact)
    expect(response.body).to include("Mariana")

    patch contact_path(contact), params: { contact: { kind: "manager" } }
    expect(contact.reload).to be_manager

    get contacts_path
    expect(response.body).to include("Gestor(a)")

    expect { delete contact_path(contact) }.to change(Contact, :count).by(-1)
  end

  it "re-renders the forms with errors" do
    post contacts_path, params: { contact: { name: "" } }
    expect(response).to have_http_status(:unprocessable_content)

    contact = create(:contact)
    patch contact_path(contact), params: { contact: { name: "" } }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
