module Api
  module V1
    # Recruiters and hiring managers saved by the extension, from a LinkedIn profile or from
    # "Meet the hiring team" on a job page. The same profile saved again only fills blanks,
    # so what you edited in WorkMachine is kept.
    class ContactsController < BaseController
      def create
        contact = find_contact(contact_params[:linkedin_url])
        duplicate = contact.present?
        contact ||= Contact.new
        contact.assign_attributes(duplicate ? contact_params.to_h.select { |field, _| contact[field].blank? } : contact_params)
        contact.notes = [ contact.notes, job_note ].compact_blank.join("\n") if job_note && !contact.notes.to_s.include?(job_url)
        return render(json: { errors: contact.errors.full_messages }, status: :unprocessable_content) unless contact.save

        name_application(contact)
        render json: contact_json(contact).merge(duplicate:), status: duplicate ? :ok : :created
      end

      def lookup
        contact = find_contact(params[:linkedin_url])
        render json: contact ? contact_json(contact).merge(found: true) : { found: false }
      end

      private
        def contact_params
          params.expect(contact: %i[ name headline company linkedin_url kind ]).compact_blank
        end

        def find_contact(url)
          Contact.find_by(linkedin_url: url) if url.present?
        end

        # The job page where the contact was found (only from "Meet the hiring team").
        def job_url
          @job_url ||= UrlNormalizer.call(params.dig(:job, :url))
        end

        def job_note
          "Vaga: #{[ params.dig(:job, :title).to_s.squish.presence, job_url ].compact.join(" — ")}" if job_url.present?
        end

        # The application for that job gets the contact's name, used by {{nome}} in Mensagens.
        def name_application(contact)
          application = JobPosting.find_by(url: job_url)&.job_application if job_url.present?
          application.update!(contact_name: contact.name) if application && application.contact_name.blank?
        end

        def contact_json(contact)
          {
            id: contact.id,
            name: contact.name,
            headline: contact.headline,
            company: contact.company,
            kind: contact.kind,
            kind_label: contact.human_enum(:kind),
            app_url: contacts_url(anchor: ActionView::RecordIdentifier.dom_id(contact))
          }
        end
    end
  end
end
