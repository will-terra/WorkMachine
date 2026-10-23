# The "ativado" box of the LinkedIn alerts in the Radar. The whole list is rendered again, since a
# checked alert moves to the end, and so are the counts of alerts left to turn on.
class ActivatedAlertsController < ApplicationController
  def create
    ActivatedAlert.find_or_create_by!(query: params.require(:query)) { it.search_key = params.require(:search_key) }
    render_list
  end

  def destroy
    ActivatedAlert.find_by(id: params[:id])&.destroy!
    render_list
  end

  private
    def render_list
      respond_to do |format|
        format.turbo_stream do
          profile = Profile.current
          pending = Radar.pending_alerts(profile)
          render turbo_stream: [
            turbo_stream.replace("linkedin_alerts_list", partial: "radar/alerts",
                                                         locals: { searches: Radar.alert_searches(profile), filters: Radar.sanitize_filters(session[:radar_filters]), location: profile.location }),
            turbo_stream.update("pending_alerts", partial: "radar/pending_alerts", locals: { count: pending }),
            turbo_stream.update("pending_alerts_count", pending.positive? ? pending.to_s : "")
          ]
        end
        format.html { redirect_to radar_path(anchor: "linkedin_alerts") }
      end
    end
end
