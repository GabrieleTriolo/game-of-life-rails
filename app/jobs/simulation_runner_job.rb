class SimulationRunnerJob < ApplicationJob
  queue_as :default

  def perform(simulation_id, interval_ms = 500)
    sim = Simulation.find(simulation_id)
    return unless sim.running?

    sleep(0.1)

    interval = interval_ms.to_i.clamp(50, 5000) / 1000.0
    current_grid = deep_dup_grid(sim.grid)
    current_gen = sim.generation

    broadcast(sim, html: render_grid(current_grid), generation: current_gen, grid: current_grid)

    loop do
      next_grid = GameOfLife.next_grid(current_grid)
      current_gen += 1

      sim.update_columns(grid: next_grid, generation: current_gen, updated_at: Time.current)

      broadcast(sim, html: render_grid(next_grid), generation: current_gen, grid: next_grid)

      if next_grid == current_grid
        Rails.logger.info("Stable configuration achieved at gen #{current_gen}")
        broadcast(sim, message: "Stable configuration reached! The pattern will no longer change.", message_type: "info")
        sleep(2)
        break
      end

      if next_grid.flatten.count('*') == 0
        Rails.logger.info("All cells are dead at the gen #{current_gen}")
        broadcast(sim, message: "All cells have died. Simulation complete.", message_type: "warning")
        sleep(2)
        break
      end

      current_grid = next_grid
      sleep(interval)

      break unless sim.reload.running?
    end
  rescue => e
    Rails.logger.error("[SimulationRunnerJob] sim=#{simulation_id} error=#{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  ensure
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