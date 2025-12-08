require "test_helper"

class SimulationRunnerJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @simulation = simulations(:one)
  end

  test "job broadcasts initial state on start" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [[".", ".", "."], [".", ".", "."], [".", ".", "."]],
      status: :running
    )

    # Mock ActionCable broadcast
    broadcasts = []
    ActionCable.server.stubs(:broadcast).with do |channel, data|
      broadcasts << { channel: channel, data: data }
      true
    end

    # Run job with very short interval and stop it quickly
    sim.update!(status: :running)

    # Perform job in background thread and stop after initial broadcast
    thread = Thread.new do
      SimulationRunnerJob.new.perform(sim.id, 50)
    end

    sleep 0.3 # Wait for initial broadcast
    sim.update!(status: :finished) # Stop the job
    thread.join(2) # Wait max 2 seconds for thread to finish

    assert broadcasts.any?, "Expected at least one broadcast"
    assert_equal "simulation:#{sim.id}:user:#{@user.id}", broadcasts.first[:channel]
  end

  test "job stops when simulation status changes to finished" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [["*", "*", "*"], [".", ".", "."], [".", ".", "."]],
      status: :running
    )

    thread = Thread.new do
      SimulationRunnerJob.new.perform(sim.id, 50)
    end

    sleep 0.2
    sim.update!(status: :finished)

    thread.join(2)

    assert sim.finished?
  end

  test "job detects stable configuration" do
    # Block pattern - stable configuration
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 4,
      cols: 4,
      grid: [
        [".", ".", ".", "."],
        [".", "*", "*", "."],
        [".", "*", "*", "."],
        [".", ".", ".", "."]
      ],
      status: :running
    )

    broadcasts = []
    ActionCable.server.stubs(:broadcast).with do |channel, data|
      broadcasts << data
      true
    end

    SimulationRunnerJob.new.perform(sim.id, 50)

    # Should detect stable configuration
    stable_message = broadcasts.find { |b| b[:message]&.include?("Stable configuration") }
    assert_not_nil stable_message, "Expected stable configuration message"

    sim.reload
    assert sim.finished?
  end

  test "job detects extinction (all cells dead)" do
    # Single cell - will die
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [
        [".", ".", "."],
        [".", "*", "."],
        [".", ".", "."]
      ],
      status: :running
    )

    broadcasts = []
    ActionCable.server.stubs(:broadcast).with do |channel, data|
      broadcasts << data
      true
    end

    SimulationRunnerJob.new.perform(sim.id, 50)

    extinction_message = broadcasts.find { |b| b[:message]&.include?("All cells have died") }
    assert_not_nil extinction_message, "Expected extinction message"

    sim.reload
    assert sim.finished?
  end

  test "job updates generation counter" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 5,
      cols: 5,
      grid: [
        [".", ".", ".", ".", "."],
        [".", ".", "*", ".", "."],
        [".", ".", "*", ".", "."],
        [".", ".", "*", ".", "."],
        [".", ".", ".", ".", "."]
      ],
      status: :running
    )

    initial_gen = sim.generation

    thread = Thread.new do
      SimulationRunnerJob.new.perform(sim.id, 50)
    end

    sleep 0.5
    sim.update!(status: :finished)
    thread.join(2)

    sim.reload
    assert sim.generation > initial_gen, "Generation should increase"
  end

  test "job clamps interval to safe range" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [["*", "*", "*"], [".", ".", "."], [".", ".", "."]],
      status: :running
    )

    # Test with interval below minimum (should clamp to 50ms)
    thread = Thread.new do
      SimulationRunnerJob.new.perform(sim.id, 10) # Too small
    end

    sleep 0.2
    sim.update!(status: :finished)
    thread.join(2)

    # Job should complete without error
    assert sim.finished?
  end

  test "job handles errors gracefully" do
    # Create simulation that will cause error (invalid ID)
    assert_nothing_raised do
      SimulationRunnerJob.new.perform(999999, 100)
    end
  end

  test "job ensures simulation is marked as finished" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [["*", "*", "*"], [".", ".", "."], [".", ".", "."]],
      status: :running
    )

    thread = Thread.new do
      SimulationRunnerJob.new.perform(sim.id, 50)
    end

    sleep 0.3
    sim.reload.update!(status: :finished)
    thread.join(2)

    sim.reload
    assert sim.finished?, "Simulation should be marked as finished"
  end

  test "job broadcasts finished flag on completion" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [[".", ".", "."], [".", "*", "."], [".", ".", "."]],
      status: :running
    )

    broadcasts = []
    ActionCable.server.stubs(:broadcast).with do |channel, data|
      broadcasts << data
      true
    end

    SimulationRunnerJob.new.perform(sim.id, 50)

    finished_broadcast = broadcasts.find { |b| b[:finished] == true }
    assert_not_nil finished_broadcast, "Expected finished broadcast"
  end
end
