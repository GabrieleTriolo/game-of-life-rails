class GameOfLife
  def self.next_grid(grid)
    rows = grid.size
    cols = grid.first.size
    new_grid = Array.new(rows) { Array.new(cols, ".") }

    (0...rows).each do |i|
      (0...cols).each do |j|
        live = count_living_neighbors(grid, i, j, rows, cols)

        if grid[i][j] == "*"
          new_grid[i][j] = (live == 2 || live == 3) ? "*" : "."
        else
          new_grid[i][j] = (live == 3) ? "*" : "."
        end
      end
    end
    new_grid
  end

  private

  def self.count_living_neighbors(grid, y, x, rows, cols)
    live = 0
    (-1..1).each do |dy|
      (-1..1).each do |dx|
        next if dy == 0 && dx == 0

        # Wrapping: use modulelo arithmetic to wrap around edges
        ny = (y + dy) % rows
        nx = (x + dx) % cols

        live += 1 if grid[ny][nx] == "*"
      end
    end
    live
  end
end