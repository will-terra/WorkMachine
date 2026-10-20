class RadarController < ApplicationController
  def show
    @filters = Radar.sanitize_filters(session.fetch(:radar_filters, {}).merge(params.permit(*Radar.filters.keys).to_h))
    session[:radar_filters] = @filters
    @config = Radar.config
    @consultancies = Consultancy.alphabetical.group_by(&:kind)
  end
end
