class ConsultanciesController < ApplicationController
  def update
    @consultancy = Consultancy.find(params[:id])
    @consultancy.update!(registered_on: params[:registered] == "1" ? (@consultancy.registered_on || Date.current) : nil)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@consultancy, partial: "consultancies/consultancy", locals: { consultancy: @consultancy }) }
      format.html { redirect_to radar_path(anchor: "consultorias") }
    end
  end
end
