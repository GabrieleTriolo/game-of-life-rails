class SimulationsController < ApplicationController
    before_action :authenticate_user!
  
    def show
      @simulation = current_user.simulations.find(params[:id])
    end
  end
  