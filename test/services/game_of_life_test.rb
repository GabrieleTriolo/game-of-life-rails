require "test_helper"

class GameOfLifeTest < ActiveSupport::TestCase
  test "dead cell with exactly 3 neighbors becomes alive (reproduction)" do
    grid = [
      ["*", "*", "."],
      ["*", ".", "."],
      [".", ".", "."]
    ]

    result = GameOfLife.next_grid(grid)

    # Cell at [1,1] should become alive (has 3 neighbors)
    assert_equal "*", result[1][1]
  end

  test "live cell with 2 neighbors survives" do
    grid = [
      ["*", "*", "."],
      ["*", ".", "."],
      [".", ".", "."]
    ]

    result = GameOfLife.next_grid(grid)

    # Cell at [0,0] should survive (has 2 neighbors)
    assert_equal "*", result[0][0]
  end

  test "live cell with 3 neighbors survives" do
    grid = [
      ["*", "*", "."],
      ["*", "*", "."],
      [".", ".", "."]
    ]

    result = GameOfLife.next_grid(grid)

    # Cell at [0,0] should survive (has 3 neighbors)
    assert_equal "*", result[0][0]
  end

  test "live cell with less than 2 neighbors dies (underpopulation)" do
    grid = [
      ["*", ".", "."],
      [".", ".", "."],
      [".", ".", "."]
    ]

    result = GameOfLife.next_grid(grid)

    # Cell at [0,0] should die (only 0 neighbors)
    assert_equal ".", result[0][0]
  end

  test "live cell with more than 3 neighbors dies (overpopulation)" do
    grid = [
      ["*", "*", "*"],
      ["*", "*", "."],
      [".", ".", "."]
    ]

    result = GameOfLife.next_grid(grid)

    # Cell at [1,1] should die (has 4 neighbors)
    assert_equal ".", result[1][1]
  end

  test "blinker pattern oscillates correctly" do
    # Horizontal blinker
    grid = [
      [".", ".", ".", ".", "."],
      [".", ".", "*", ".", "."],
      [".", ".", "*", ".", "."],
      [".", ".", "*", ".", "."],
      [".", ".", ".", ".", "."]
    ]

    # After one generation, should become vertical
    result = GameOfLife.next_grid(grid)
    assert_equal ".", result[1][2]
    assert_equal "*", result[2][1]
    assert_equal "*", result[2][2]
    assert_equal "*", result[2][3]

    # After two generations, should return to horizontal
    result2 = GameOfLife.next_grid(result)
    assert_equal grid, result2
  end

  test "block pattern remains stable (still life)" do
    grid = [
      [".", ".", ".", "."],
      [".", "*", "*", "."],
      [".", "*", "*", "."],
      [".", ".", ".", "."]
    ]

    result = GameOfLife.next_grid(grid)

    # Block should remain unchanged
    assert_equal grid, result
  end

  test "wrapping works on top edge" do
    # Star at top edge should count bottom neighbors
    grid = [
      [".", "*", "."],
      [".", ".", "."],
      ["*", "*", "."]
    ]

    result = GameOfLife.next_grid(grid)

    # Cell at [0,1] has neighbors at [2,0], [2,1], [2,2] (wrapping)
    # Total: 2 neighbors, so it should survive
    assert_equal "*", result[0][1]
  end

  test "wrapping works on left edge" do
    grid = [
      [".", ".", "*"],
      ["*", ".", "*"],
      [".", ".", "*"]
    ]

    result = GameOfLife.next_grid(grid)

    # Cell at [1,0] should count right edge as neighbors
    assert_equal "*", result[1][0]
  end

  test "wrapping works on corners" do
    # Test that corner cell wraps both horizontally and vertically
    grid = [
      ["*", ".", "."],
      [".", ".", "."],
      [".", ".", "*"]
    ]

    result = GameOfLife.next_grid(grid)

    # Cell at [0,0] has neighbors at [2,2] due to wrapping
    # Only 1 neighbor, should die
    assert_equal ".", result[0][0]
  end

  test "empty grid remains empty" do
    grid = [
      [".", ".", "."],
      [".", ".", "."],
      [".", ".", "."]
    ]

    result = GameOfLife.next_grid(grid)

    assert_equal grid, result
  end

  test "glider pattern moves correctly (first step)" do
    grid = [
      [".", ".", ".", ".", "."],
      [".", ".", "*", ".", "."],
      [".", ".", ".", "*", "."],
      [".", "*", "*", "*", "."],
      [".", ".", ".", ".", "."]
    ]

    result = GameOfLife.next_grid(grid)

    # Verify glider has moved/transformed
    assert_equal "*", result[2][1]
    assert_equal "*", result[3][2]
    assert_equal "*", result[3][3]
  end

  test "works with single cell grid" do
    grid = [["*"]]

    result = GameOfLife.next_grid(grid)

    # Single cell with wrapping has 0 neighbors, should die
    assert_equal ".", result[0][0]
  end

  test "works with 2x2 grid" do
    grid = [
      ["*", "*"],
      ["*", "."]
    ]

    result = GameOfLife.next_grid(grid)

    # Each live cell has enough neighbors to survive or die based on rules
    assert_equal "*", result[0][0]
    assert_equal "*", result[0][1]
    assert_equal "*", result[1][0]
  end

  test "works with rectangular grid (more columns than rows)" do
    grid = [
      [".", "*", "*", "*", "."],
      [".", ".", ".", ".", "."]
    ]

    result = GameOfLife.next_grid(grid)

    # Middle cell should survive, edges should die
    assert_equal ".", result[0][1]
    assert_equal "*", result[0][2]
    assert_equal ".", result[0][3]
  end

  test "works with rectangular grid (more rows than columns)" do
    grid = [
      [".", "."],
      ["*", "."],
      ["*", "."],
      ["*", "."],
      [".", "."]
    ]

    result = GameOfLife.next_grid(grid)

    # Should form horizontal pattern
    assert_equal "*", result[2][0]
    assert_equal "*", result[2][1]
  end
end
