module Api
    class SimulationsController < ApplicationController
      before_action :authenticate_user!
  
      def create
        file = params[:generation_file]
        return render json: { error: "File mancante" }, status: :bad_request if file.blank?
  
        content = file.read
        begin
          parsed = GolInputParser.parse!(content)
        rescue GolInputParser::ParseError => e
          return render json: { error: e.message }, status: :unprocessable_entity
        end
  
        grid_2d = parsed.grid_lines.map(&:chars)
        sim = current_user.simulations.create!(
          generation: parsed.generation,
          rows: parsed.rows,
          cols: parsed.cols,
          grid: grid_2d,
          status: :pending
        )
  
        render json: { id: sim.id }, status: :created
      end
  
      def start
        sim = current_user.simulations.find(params[:id])
        sim.update!(status: :running)
        SimulationRunnerJob.perform_later(sim.id, interval_ms_param)
        head :ok
      end
  
      private
  
      def interval_ms_param
        (params[:interval_ms] || 500).to_i.clamp(50, 5000)
      end
    end
  end
  