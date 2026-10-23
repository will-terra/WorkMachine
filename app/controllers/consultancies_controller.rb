class ConsultanciesController < ApplicationController
  def update
    @consultancy = Consultancy.find(params[:id])
    @consultancy.update!(registered_on: params[:registered] == "1" ? (@consultancy.registered_on || Date.current) : nil)

    respond_to do |format|
      # The whole list again: a checked one folds into its group's "cadastrados".
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("registrations", partial: "radar/registrations",
                                                                   locals: { registrations: Consultancy.alphabetical.group_by(&:kind), keywords: Radar.profile_keywords,
                                                                             open_kind: params[:keep_open] })
      end
      format.html { redirect_to radar_path(anchor: "cadastros") }
    end
  end
end
