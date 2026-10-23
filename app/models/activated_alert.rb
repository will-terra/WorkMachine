# A LinkedIn job alert the person turned on from a search of the Radar (Alertas do LinkedIn). It is
# tied to the query, not to the search: when a change in the profile changes the query, the search
# comes back as a new alert to turn on, and this one is listed as outdated, to turn off on LinkedIn.
class ActivatedAlert < ApplicationRecord
  validates :search_key, presence: true
  validates :query, presence: true, uniqueness: true

  # The alert searches in the order to work on them: the ones to turn on first (in the order of
  # config/radar.yml), then the ones already on, the latest at the end. Each comes with its
  # ActivatedAlert, or nil.
  def self.sorted(searches)
    activations = where(query: searches.map { it["query"] }).index_by(&:query)
    pending, activated = searches.map { [ it, activations[it["query"]] ] }.partition { |_, activation| activation.nil? }
    pending + activated.sort_by { |_, activation| activation.created_at }
  end

  def self.pending_count(searches)
    searches.size - where(query: searches.map { it["query"] }).count
  end

  # Turned on for a query that the profile no longer makes.
  def self.outdated(searches)
    where.not(query: searches.map { it["query"] }).order(:created_at)
  end
end
