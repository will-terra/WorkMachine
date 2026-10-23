# The "ativado" box of the LinkedIn alerts in the Radar. The whole list is rendered again, since a
# checked alert moves to the end, and so are the summary on top and the count on the tab.
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
          summary = Radar.alerts_summary(profile)
          pending = summary&.pending.to_i
          render turbo_stream: [
            turbo_stream.replace("linkedin_alerts_list", partial: "radar/alerts",
                                                         locals: { task: Radar.alerts_task(profile), filters: Radar.sanitize_filters(session[:radar_filters]),
                                                                   available: Radar.filters, location: profile.location, done_open: params[:keep_open].present? }),
            turbo_stream.update("alerts_summary", partial: "radar/alerts_summary", locals: { summary: }),
            turbo_stream.update("pending_alerts_count", pending.positive? ? pending.to_s : "")
          ]
        end
        format.html { redirect_to radar_path(anchor: "linkedin_alerts") }
      end
    end
end
