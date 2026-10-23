class MetricsController < ApplicationController
  def show
    @metrics = FunnelMetrics.new(period: params[:period])
    @week = WeeklySummary.new
  end
end
