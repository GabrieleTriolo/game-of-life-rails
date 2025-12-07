class GolInputParser
    ParseResult = Struct.new(:generation, :rows, :cols, :grid_lines, keyword_init: true)
  
    class ParseError < StandardError; end
  
    HEADER_RE = /\AGeneration\s+(\d+):\z/
  
    def self.parse!(content)
      lines = content.split(/\r?\n/).map(&:strip)
      raise ParseError, "Formato invalido: file vuoto" if lines.size < 3
  
      m = lines[0].match(HEADER_RE)
      raise ParseError, "Header generazione mancante o invalido" unless m
      generation = m[1].to_i
  
      dims = lines[1].split
      raise ParseError, "Riga dimensioni invalida" unless dims.size == 2 && dims.all? { |x| x =~ /^\d+$/ }
      rows, cols = dims.map!(&:to_i)
  
      grid = lines[2..]
      raise ParseError, "Numero righe griglia (#{grid.size}) diverso da rows (#{rows})" unless grid.size == rows
      raise ParseError, "Lunghezza di una o più righe diversa da cols (#{cols})" if grid.any? { |r| r.length != cols }
      raise ParseError, "La griglia può contenere solo '*' e '.'" if grid.any? { |r| r =~ /[^.*]/ }
  
      ParseResult.new(generation:, rows:, cols:, grid_lines: grid)
    end
  end
  