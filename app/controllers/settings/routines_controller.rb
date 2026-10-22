# Ajustes → Rotinas: edit the checklists of the Rotina page (slots, items, periods and links).
class Settings::RoutinesController < ApplicationController
  before_action :set_routine, only: %i[ edit update destroy ]

  def index
    @routines = Routine.current
  end

  def new
    @routine = Routine.new(position: (Routine.maximum(:position) || -1) + 1)
    @routine.slots.build(period: "daily").items.build
  end

  def create
    @routine = Routine.new(routine_params)

    if @routine.save
      redirect_to settings_routines_path, notice: t("flash.routines.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @routine.update(routine_params)
      redirect_to settings_routines_path, notice: t("flash.routines.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @routine.destroy!
    redirect_to settings_routines_path, notice: t("flash.routines.deleted")
  end

  def restore
    Routine.restore_defaults!
    redirect_to settings_routines_path, notice: t("flash.routines.restored")
  end

  private
    def set_routine
      @routine = Routine.find(params[:id])
    end

    def routine_params
      params.expect(routine: [ :name, :description, :position,
                               slots_attributes: [ [ :id, :title, :time, :period, :position, :_destroy,
                                                     items_attributes: [ [ :id, :label, :url, :position, :_destroy ] ] ] ] ])
    end
end
