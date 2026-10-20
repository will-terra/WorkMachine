class RadarController < ApplicationController
  def show
    @filters = Radar.sanitize_filters(session.fetch(:radar_filters, {}).merge(params.permit(*Radar.filters.keys).to_h))
    session[:radar_filters] = @filters
    @config = Radar.config
    # LinkedIn · Vagas is only used to create the alerts once, so it goes to the end of the page.
    @sections, @closing_sections = @config.fetch("sections").partition { it["placement"] != "end" }
    @consultancies = Consultancy.alphabetical.group_by(&:kind)
    @automated = Radar.automated
    @gmail_configured = LinkedinAlerts::Importer.configured?
  end
end
