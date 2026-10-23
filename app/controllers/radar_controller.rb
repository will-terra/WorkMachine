class RadarController < ApplicationController
  def show
    @filters = Radar.sanitize_filters(session.fetch(:radar_filters, {}).merge(params.permit(*Radar.filters.keys).to_h))
    session[:radar_filters] = @filters
    @config = Radar.config
    @profile = Profile.current
    @tasks = Radar.tasks_for(@profile).group_by { it["cadence"] }
    # A filter reloads only its task's frame ("radar_google"): that task comes back open.
    @open_task = request.headers["Turbo-Frame"].to_s.delete_prefix("radar_").presence
    @folds = folds
    @alerts_summary = Radar.alerts_summary(@profile)
    @automated = Radar.automated
    @gmail_configured = LinkedinAlerts::Importer.configured?
    @alerts = { emails: ProcessedEmail.count, last_received_at: ProcessedEmail.maximum(:received_at) }
    @registrations = Consultancy.alphabetical.group_by(&:kind)
    @new_postings_count = JobPosting.triage_new.count
  end

  private
    # The sections the person left open (1) or folded (0), kept by radar_folds_controller.js in a
    # cookie so the page comes back as it was, already from the server.
    def folds
      data = JSON.parse(cookies[:radar_folds].to_s)
      return {} unless data.is_a?(Hash)

      data.slice(*Radar.tasks.map { it["key"] }).transform_values { it == 1 }
    rescue JSON::ParserError
      {}
    end
end
