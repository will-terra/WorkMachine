module Sources
  # Public job boards of the companies in TargetCompany. One call per active company;
  # only engineering roles are kept and a failing company does not stop the others.
  class AtsBoard < Base
    ENGINEERING = /engineer|developer|desenvolvedor|programador|software|full[ -]?stack|back[ -]?end|front[ -]?end/i
    # Pause between two boards of the same ATS (Workable answers 429 to quick bursts).
    PAUSE = Rails.env.test? ? 0 : 0.5

    def fetch
      TargetCompany.active.where(ats: key).order(:name).each_with_index.flat_map do |company, index|
        sleep PAUSE if index.positive?
        jobs = fetch_company(company).select { it[:title].to_s.match?(ENGINEERING) }
        company.update!(last_fetched_at: Time.current)
        jobs
      rescue HttpClient::Error => e
        warnings << "#{company.name}: #{e.message}"
        []
      end
    end

    private
      def fetch_company(_company)
        raise NotImplementedError
      end
  end
end
