class MetricsController < ApplicationController
  def show
    @metrics = FunnelMetrics.new(period: params[:period])
  end
end
