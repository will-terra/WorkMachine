class RadarController < ApplicationController
  def show
    @filters = Radar.sanitize_filters(session.fetch(:radar_filters, {}).merge(params.permit(*Radar.filters.keys).to_h))
    session[:radar_filters] = @filters
    @config = Radar.config
    @profile = Profile.current
    @tasks = Radar.tasks_for(@profile).group_by { it["cadence"] }
    @automated = Radar.automated
    @gmail_configured = LinkedinAlerts::Importer.configured?
    @alerts = { emails: ProcessedEmail.count, last_received_at: ProcessedEmail.maximum(:received_at) }
    @registrations = Consultancy.alphabetical.group_by(&:kind)
    @new_postings_count = JobPosting.triage_new.count
  end
end
