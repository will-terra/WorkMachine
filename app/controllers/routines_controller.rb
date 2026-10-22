class RoutinesController < ApplicationController
  def show
    @routines = Routine.current
    @checked = Routine.checked_keys
  end

  def toggle
    Routine.toggle!(params[:key])
    @checked = Routine.checked_keys
    @item = Routine.find_item(params[:key])
    @routine = @item.slot.routine

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back_or_to routine_path }
    end
  end
end
