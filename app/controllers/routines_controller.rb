class RoutinesController < ApplicationController
  def show
    @checked = Routine.checked_keys
  end

  def toggle
    Routine.toggle!(params[:key])
    @checked = Routine.checked_keys
    @item = Routine.find_item(params[:key])

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back_or_to routine_path }
    end
  end
end
