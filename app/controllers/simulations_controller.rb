class SimulationsController < ApplicationController
    before_action :authenticate_user!

    def index
      @simulations = current_user.simulations.order(created_at: :desc)
    end
  
    def show
      @simulation = current_user.simulations.find(params[:id])
    end
  end
  