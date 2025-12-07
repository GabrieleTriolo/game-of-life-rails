class SimulationChannel < ApplicationCable::Channel
  def subscribed
    simulation = current_user.simulations.find(params[:simulation_id])
    stream_name = "simulation:#{simulation.id}:user:#{current_user.id}"
    stream_from stream_name
  end

  def unsubscribed
    # Cleanup quando il client si disconnette
    stop_all_streams
  end
end