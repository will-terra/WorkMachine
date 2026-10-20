module ApplicationReplies
  # Finds which open application an e-mail is about, from the company name in the sender
  # name or the subject ("Acme Recruiting", "Your application to Acme") or the sender domain.
  class Matcher
    OPEN_STATUSES = %w[applied no_response recruiter_contact hr_interview tech_interview take_home offer].freeze
    PROVIDER_LABELS = %w[com br io net org co mail email gmail outlook hotmail yahoo app jobs careers hire noreply no reply].freeze

    def initialize(applications = JobApplication.where(status: OPEN_STATUSES))
      @entries = applications.filter_map do |application|
        words = self.class.words(application.company.to_s.sub(/\(.*?\)/, "")) - TargetCompanyFinder::GENERIC_WORDS
        [ application, words ] if words.join.length >= 3
      end
    end

    def self.words(text)
      I18n.transliterate(text.to_s).downcase.scan(/[a-z0-9]+/)
    end

    def match(from_name:, from_address:, subject:)
      text = self.class.words("#{from_name} #{subject}")
      labels = from_address.to_s.split("@").last.to_s.downcase.split(".") - PROVIDER_LABELS

      candidates = @entries.select { |_, company| sequence?(text, company) || labels.include?(company.join) }
      candidates.max_by { |application, company| [ company.size, role_overlap(application, text), application.applied_on || Date.new(1970) ] }&.first
    end

    private
      def sequence?(text, company)
        text.each_cons(company.size).any?(company)
      end

      def role_overlap(application, text)
        (self.class.words(application.role) & text).size
      end
  end
end
