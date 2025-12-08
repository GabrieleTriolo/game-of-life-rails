require "test_helper"

class Api::SimulationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @simulation = simulations(:one)
    sign_in @user
  end

  test "should require authentication for create" do
    sign_out @user

    post api_simulations_path, params: { generation_file: fixture_file_upload('valid_game.txt', 'text/plain') }

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "should create simulation with valid file" do
    file = fixture_file_upload('valid_game.txt', 'text/plain')

    assert_difference('Simulation.count', 1) do
      post api_simulations_path, params: { generation_file: file }
    end

    assert_response :created

    json = JSON.parse(response.body)
    assert json['id'].present?

    sim = Simulation.find(json['id'])
    assert_equal @user.id, sim.user_id
    assert_equal 'pending', sim.status
  end

  test "should return error when file is missing" do
    assert_no_difference('Simulation.count') do
      post api_simulations_path, params: {}
    end

    assert_response :bad_request

    json = JSON.parse(response.body)
    assert_equal 'Missing file', json['error']
  end

  test "should return error for invalid file format" do
    file = fixture_file_upload('invalid_game.txt', 'text/plain')

    assert_no_difference('Simulation.count') do
      post api_simulations_path, params: { generation_file: file }
    end

    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert json['error'].present?
  end

  test "should start simulation" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [[".", "*", "."], ["*", "*", "*"], [".", "*", "."]],
      status: :pending
    )

    assert_enqueued_with(job: SimulationRunnerJob) do
      post "/api/simulations/#{sim.id}/start"
    end

    assert_response :success

    sim.reload
    assert_equal 'running', sim.status
  end

  test "should stop simulation" do
    sim = Simulation.create!(
      user: @user,
      generation: 5,
      rows: 3,
      cols: 3,
      grid: [[".", "*", "."], ["*", "*", "*"], [".", "*", "."]],
      status: :running
    )

    post "/api/simulations/#{sim.id}/stop"

    assert_response :success

    sim.reload
    assert_equal 'finished', sim.status
  end

  test "should only access own simulations" do
    other_user = users(:two)
    other_sim = Simulation.create!(
      user: other_user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [["*", "*", "*"], [".", ".", "."], [".", ".", "."]],
      status: :pending
    )

    # Try to start a simulation that belongs to another user
    post "/api/simulations/#{other_sim.id}/start"

    assert_response :not_found
  end

  test "should accept custom interval parameter" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [[".", "*", "."], ["*", "*", "*"], [".", "*", "."]],
      status: :pending
    )

    assert_enqueued_with(job: SimulationRunnerJob, args: [sim.id, 1000]) do
      post "/api/simulations/#{sim.id}/start", params: { interval_ms: 1000 }
    end

    assert_response :success
  end

  test "should clamp interval to minimum value" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [[".", "*", "."], ["*", "*", "*"], [".", "*", "."]],
      status: :pending
    )

    # Try to set interval below minimum (50ms)
    assert_enqueued_with(job: SimulationRunnerJob, args: [sim.id, 50]) do
      post "/api/simulations/#{sim.id}/start", params: { interval_ms: 10 }
    end

    assert_response :success
  end

  test "should clamp interval to maximum value" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [[".", "*", "."], ["*", "*", "*"], [".", "*", "."]],
      status: :pending
    )

    # Try to set interval above maximum (5000ms)
    assert_enqueued_with(job: SimulationRunnerJob, args: [sim.id, 5000]) do
      post "/api/simulations/#{sim.id}/start", params: { interval_ms: 10000 }
    end

    assert_response :success
  end

  test "should use default interval when not specified" do
    sim = Simulation.create!(
      user: @user,
      generation: 0,
      rows: 3,
      cols: 3,
      grid: [[".", "*", "."], ["*", "*", "*"], [".", "*", "."]],
      status: :pending
    )

    assert_enqueued_with(job: SimulationRunnerJob, args: [sim.id, 500]) do
      post "/api/simulations/#{sim.id}/start"
    end

    assert_response :success
  end
end
