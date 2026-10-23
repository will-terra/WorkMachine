module ContactsHelper
  # Your contacts at a company (CompanyName), looked up once per page.
  def contacts_at(company)
    key = CompanyName.key(company) or return []
    (@contacts_by_company ||= Contact.by_company).fetch(key, [])
  end

  # Mensagens with the referral request filled in for this contact and this job or application.
  def referral_path(contact, record)
    @referral_template = MessageTemplate.referral unless defined?(@referral_template)
    context = record.is_a?(JobApplication) ? { job_application_id: record.id } : { job_posting_id: record.id }
    message_templates_path(**context, nome: contact.first_name, template_id: @referral_template&.id,
                                      anchor: (dom_id(@referral_template) if @referral_template))
  end
end
