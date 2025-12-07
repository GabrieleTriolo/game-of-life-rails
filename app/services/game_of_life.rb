class GameOfLife
    def self.next_grid(grid)
      rows = grid.size
      cols = grid.first.size
      new_grid = Array.new(rows) { Array.new(cols, ".") }
      offsets = [-1, 0, 1]
  
      (0...rows).each do |i|
        (0...cols).each do |j|
          live = 0
          offsets.each do |di|
            offsets.each do |dj|
              next if di == 0 && dj == 0
              ni, nj = i + di, j + dj
              live += 1 if ni.between?(0, rows-1) && nj.between?(0, cols-1) && grid[ni][nj] == "*"
            end
          end
  
          if grid[i][j] == "*"
            new_grid[i][j] = live < 2 || live > 3 ? "." : "*"
          else
            new_grid[i][j] = live == 3 ? "*" : "."
          end
        end
      end
      new_grid
    end
  end  