require "test_helper"

class SimulationTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "should be valid with valid attributes" do
    sim = Simulation.new(
      user: @user,
      generation: 0,
      rows: 5,
      cols: 5,
      grid: [[".", "*", "."], ["*", "*", "*"], [".", "*", "."]],
      status: :pending
    )

    assert sim.valid?
  end

  test "should require user" do
    sim = Simulation.new(
      generation: 0,
      rows: 5,
      cols: 5,
      grid: [["*", "*"], ["*", "*"]],
      status: :pending
    )

    assert_not sim.valid?
    assert sim.errors[:user].any?
  end

  test "should require generation" do
    sim = Simulation.new(
      user: @user,
      rows: 5,
      cols: 5,
      grid: [["*", "*"], ["*", "*"]],
      status: :pending
    )

    assert_not sim.valid?
    assert sim.errors[:generation].any?
  end

  test "should require rows" do
    sim = Simulation.new(
      user: @user,
      generation: 0,
      cols: 5,
      grid: [["*", "*"], ["*", "*"]],
      status: :pending
    )

    assert_not sim.valid?
    assert sim.errors[:rows].any?
  end

  test "should require cols" do
    sim = Simulation.new(
      user: @user,
      generation: 0,
      rows: 5,
      grid: [["*", "*"], ["*", "*"]],
      status: :pending
    )

    assert_not sim.valid?
    assert sim.errors[:cols].any?
  end

  test "rows should be greater than zero" do
    sim = Simulation.new(
      user: @user,
      generation: 0,
      rows: 0,
      cols: 5,
      grid: [[]],
      status: :pending
    )

    assert_not sim.valid?
    assert sim.errors[:rows].any?
  end

  test "cols should be greater than zero" do
    sim = Simulation.new(
      user: @user,
      generation: 0,
      rows: 5,
      cols: 0,
      grid: [[]],
      status: :pending
    )

    assert_not sim.valid?
    assert sim.errors[:cols].any?
  end

  test "should default to pending status" do
    sim = Simulation.new(
      user: @user,
      generation: 0,
      rows: 5,
      cols: 5,
      grid: [["*", "*"], ["*", "*"]]
    )

    assert_equal 'pending', sim.status
  end

  test "should have pending status enum" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [["*", "*", "*"], [".", ".", "."], [".", ".", "."]],
      status: :pending
    )

    assert sim.pending?
    assert_not sim.running?
    assert_not sim.finished?
  end

  test "should have running status enum" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [["*", "*", "*"], [".", ".", "."], [".", ".", "."]],
      status: :running
    )

    assert sim.running?
    assert_not sim.pending?
    assert_not sim.finished?
  end

  test "should have finished status enum" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [["*", "*", "*"], [".", ".", "."], [".", ".", "."]],
      status: :finished
    )

    assert sim.finished?
    assert_not sim.pending?
    assert_not sim.running?
  end

  test "should store grid as JSONB" do
    grid = [["*", ".", "*"], [".", "*", "."], ["*", ".", "*"]]
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: grid,
      status: :pending
    )

    sim.reload
    assert_equal grid, sim.grid
  end

  test "should belong to user" do
    sim = simulations(:one)
    assert_instance_of User, sim.user
  end

  test "should allow updating grid" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [[".", ".", "."], [".", ".", "."], [".", ".", "."]],
      status: :pending
    )

    new_grid = [["*", "*", "*"], ["*", "*", "*"], ["*", "*", "*"]]
    sim.update!(grid: new_grid)

    sim.reload
    assert_equal new_grid, sim.grid
  end

  test "should allow updating generation" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [[".", ".", "."], [".", ".", "."], [".", ".", "."]],
      status: :pending
    )

    sim.update!(generation: 42)

    sim.reload
    assert_equal 42, sim.generation
  end

  test "should transition from pending to running" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [["*", "*", "*"], [".", ".", "."], [".", ".", "."]],
      status: :pending
    )

    sim.update!(status: :running)

    assert sim.running?
  end

  test "should transition from running to finished" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [["*", "*", "*"], [".", ".", "."], [".", ".", "."]],
      status: :running
    )

    sim.update!(status: :finished)

    assert sim.finished?
  end
end
