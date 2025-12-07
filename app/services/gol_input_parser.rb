class GolInputParser
  ParseResult = Struct.new(:generation, :rows, :cols, :grid_lines, keyword_init: true)

  class ParseError < StandardError; end

  MAX_GRID_SIZE = 100 # Maximum rows or columns to prevent memory issues

  def self.parse!(content)
    lines = normalize_lines(content)
    validate_file_structure!(lines)

    generation = parse_generation_number(lines[0])
    rows, cols = parse_dimensions!(lines[1])
    grid_lines = parse_grid!(lines[2..], rows, cols)

    ParseResult.new(generation: generation, rows: rows, cols: cols, grid_lines: grid_lines)
  end

  private

  def self.normalize_lines(content)
    raise ParseError, "File is empty" if content.nil? || content.strip.empty?
    
    content.split(/\r?\n/).map(&:strip).reject(&:empty?)
  end

  def self.validate_file_structure!(lines)
    if lines.size < 3
      raise ParseError, "Invalid file format: expected at least 3 lines (generation number, dimensions, grid)"
    end
  end

  def self.parse_generation_number(line)
    # Extract any number from the first line, default to 0 if not found
    match = line.match(/(\d+)/)
    generation = match ? match[1].to_i : 0
    
    if generation.negative?
      raise ParseError, "Generation number cannot be negative"
    end

    generation
  end

  def self.parse_dimensions!(line)
    parts = line.split
    
    unless parts.size == 2 && parts.all? { |x| x =~ /^\d+$/ }
      raise ParseError, "Invalid dimensions line. Expected format: 'ROWS COLS' (e.g., '5 8')"
    end

    rows, cols = parts.map(&:to_i)

    if rows <= 0 || cols <= 0
      raise ParseError, "Grid dimensions must be positive (got rows=#{rows}, cols=#{cols})"
    end

    if rows > MAX_GRID_SIZE || cols > MAX_GRID_SIZE
      raise ParseError, "Grid dimensions too large (max #{MAX_GRID_SIZE}x#{MAX_GRID_SIZE}, got #{rows}x#{cols})"
    end

    [rows, cols]
  end

  def self.parse_grid!(grid_lines, expected_rows, expected_cols)
    if grid_lines.size != expected_rows
      raise ParseError, "Grid has #{grid_lines.size} rows but expected #{expected_rows}"
    end

    grid_lines.each_with_index do |line, index|
      if line.length != expected_cols
        raise ParseError, "Row #{index + 1} has #{line.length} cells but expected #{expected_cols}"
      end

      unless line =~ /^[.*]+$/
        invalid_chars = line.chars.reject { |c| c == '*' || c == '.' }.uniq.join(', ')
        raise ParseError, "Row #{index + 1} contains invalid characters: '#{invalid_chars}'. Only '*' (alive) and '.' (dead) are allowed"
      end
    end

    grid_lines
  end
end