class ConsultanciesController < ApplicationController
  def update
    @consultancy = Consultancy.find(params[:id])
    @consultancy.update!(registered_on: params[:registered] == "1" ? (@consultancy.registered_on || Date.current) : nil)

    respond_to do |format|
      format.turbo_stream do
        same_kind = Consultancy.where(kind: @consultancy.kind)
        render turbo_stream: [
          turbo_stream.replace(@consultancy, partial: "consultancies/consultancy", locals: { consultancy: @consultancy }),
          turbo_stream.update("registrations_count_#{@consultancy.kind}", "#{same_kind.where.not(registered_on: nil).count}/#{same_kind.count}"),
          turbo_stream.update("registrations_total", partial: "radar/registrations_total", locals: { all: Consultancy.all })
        ]
      end
      format.html { redirect_to radar_path(anchor: "cadastros") }
    end
  end
end
