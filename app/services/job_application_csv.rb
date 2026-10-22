require "csv"

# CSV import/export of the applications ("a planilha"). Headers are in Portuguese; on import,
# headers are matched without accents or case, status accepts the key or the Portuguese label,
# and dates accept 2026-10-20 or 20/10/2026. Excel's ";" separator is detected.
class JobApplicationCsv
  COLUMNS = {
    "empresa" => :company,
    "vaga" => :role,
    "origem" => :origin,
    "status" => :status,
    "aplicou_em" => :applied_on,
    "proximo_follow_up" => :next_follow_up_on,
    "contato" => :contact_name,
    "link" => :contact_url,
    "faixa_salarial" => :salary_range,
    "notas" => :notes
  }.freeze
  DATE_COLUMNS = %i[applied_on next_follow_up_on].freeze
  BOM = "﻿".freeze

  Result = Data.define(:created, :errors)

  def self.export(scope)
    BOM + CSV.generate do |csv|
      csv << COLUMNS.keys
      scope.each do |application|
        csv << COLUMNS.values.map do |attribute|
          case attribute
          when :status then application.human_enum(:status)
          when :contact_url then application.url
          else application.public_send(attribute)
          end
        end
      end
    end
  end

  def self.import(text)
    new(text).import
  end

  def initialize(text)
    @text = text.to_s.dup.force_encoding(Encoding::UTF_8).scrub.delete_prefix(BOM)
  end

  def import
    created = 0
    errors = []

    rows.each.with_index(2) do |row, line|
      next if row.fields.all?(&:blank?)

      application = JobApplication.new(attributes_for(row))
      application.save ? created += 1 : errors << I18n.t("job_application_csv.line", line:, message: application.errors.full_messages.to_sentence)
    rescue ArgumentError => e
      errors << I18n.t("job_application_csv.line", line:, message: e.message)
    end

    Result.new(created:, errors:)
  rescue CSV::MalformedCSVError => e
    Result.new(created: 0, errors: [ I18n.t("job_application_csv.invalid", message: e.message) ])
  end

  private
    def rows
      CSV.parse(@text, headers: true, col_sep: separator, skip_blanks: true)
    end

    def separator
      header = @text.lines.first.to_s
      header.count(";") > header.count(",") ? ";" : ","
    end

    def attributes_for(row)
      row.to_h.each_with_object({}) do |(header, value), attributes|
        attribute = column_for(header) or next
        value = value.to_s.strip.presence
        attributes[attribute] =
          if attribute == :status then parse_status(value)
          elsif DATE_COLUMNS.include?(attribute) then parse_date(value)
          else value
          end
      end
    end

    def column_for(header)
      key = I18n.transliterate(header.to_s).downcase.gsub(/[^a-z0-9]+/, "_").delete_prefix("_").delete_suffix("_")
      COLUMNS[key] || COLUMNS.values.find { |attribute| attribute.to_s == key }
    end

    def parse_status(value)
      return "saved" if value.blank?

      wanted = I18n.transliterate(value).downcase
      JobApplication::STATUSES.find do |status|
        names = I18n.available_locales.map { |locale| I18n.with_locale(locale) { JobApplication.human_enum(:status, status) } }
        status == wanted || names.any? { I18n.transliterate(it).downcase == wanted }
      end or raise ArgumentError, I18n.t("job_application_csv.unknown_status", value:)
    end

    def parse_date(value)
      return if value.blank?

      value.include?("/") ? Date.strptime(value, "%d/%m/%Y") : Date.iso8601(value)
    rescue Date::Error
      raise ArgumentError, I18n.t("job_application_csv.invalid_date", value:)
    end
end
