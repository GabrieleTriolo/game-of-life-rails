class SimulationRunnerJob < ApplicationJob
  queue_as :default

  def perform(simulation_id, interval_ms = 500)
    sim = Simulation.find(simulation_id)
    return unless sim.running?

    sleep(0.1) # Dai tempo al client di sottoscriversi

    interval = interval_ms.to_i.clamp(50, 5000) / 1000.0
    current_grid = deep_dup_grid(sim.grid)
    current_gen = sim.generation

    # Prima broadcast: stato iniziale
    broadcast(sim, html: render_grid(current_grid), generation: current_gen, grid: current_grid)

    # Esegui 50 generazioni
    50.times do
      next_grid = GameOfLife.next_grid(current_grid)
      current_gen += 1

      # Salva lo stato nel database
      sim.update_columns(grid: next_grid, generation: current_gen, updated_at: Time.current)

      # Broadcast la nuova generazione
      broadcast(sim, html: render_grid(next_grid), generation: current_gen, grid: next_grid)

      current_grid = next_grid
      sleep(interval)

      # Se l'utente ha fermato la simulazione, esci
      break unless sim.reload.running?
    end
  rescue => e
    Rails.logger.error("[SimulationRunnerJob] sim=#{simulation_id} error=#{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  ensure
    # Marca come finita e invia notifica finale
    if sim&.persisted?
      sim.update!(status: :finished) unless sim.finished?
      broadcast(sim, finished: true)
    end
  end

  private

  def deep_dup_grid(grid)
    grid.map { |row| row.dup }
  end

  def render_grid(grid)
    ApplicationController.render(
      partial: "simulations/grid",
      locals: { grid: grid }
    )
  end

  def broadcast(sim, payload)
    ActionCable.server.broadcast(stream_name(sim), payload)
  end

  def stream_name(sim)
    "simulation:#{sim.id}:user:#{sim.user_id}"
  end
end