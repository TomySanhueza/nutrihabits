class Pats::StatusController < ApplicationController
  before_action :authenticate_patient!

  def update
    @plan = current_patient.plans.find_or_create_by(date: Date.today)
    
    case params[:type]
    when 'energy'
      @plan.update(energy_level: params[:value])
    when 'mood'
      @plan.update(mood: params[:value])
    when 'activity'
      @plan.update(activity: params[:value])
    end

    respond_to do |format|
      format.json { render json: { status: 'success' } }
    end
  end
end