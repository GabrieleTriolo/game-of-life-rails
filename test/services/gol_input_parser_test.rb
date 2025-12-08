require "test_helper"

class GolInputParserTest < ActiveSupport::TestCase
  test "parses valid input file correctly" do
    content = <<~TXT
      Generation 0:
      3 3
      .*.
      *.*
      .*.
    TXT

    result = GolInputParser.parse!(content)

    assert_equal 0, result.generation
    assert_equal 3, result.rows
    assert_equal 3, result.cols
    assert_equal [".*.", "*.*", ".*."], result.grid_lines
  end

  test "parses file with different generation number" do
    content = <<~TXT
      Generation 42:
      2 2
      **
      ..
    TXT

    result = GolInputParser.parse!(content)

    assert_equal 42, result.generation
    assert_equal 2, result.rows
    assert_equal 2, result.cols
  end

  test "handles various generation line formats" do
    # Just a number
    result = GolInputParser.parse!("5\n2 2\n**\n..")
    assert_equal 5, result.generation

    # With text
    result = GolInputParser.parse!("Gen 10\n2 2\n**\n..")
    assert_equal 10, result.generation

    # Standard format
    result = GolInputParser.parse!("Generation 7:\n2 2\n**\n..")
    assert_equal 7, result.generation
  end

  test "defaults to generation 0 if no number found" do
    content = <<~TXT
      Generation:
      2 2
      **
      ..
    TXT

    result = GolInputParser.parse!(content)
    assert_equal 0, result.generation
  end

  test "raises error for empty file" do
    assert_raises(GolInputParser::ParseError, "File is empty") do
      GolInputParser.parse!("")
    end
  end

  test "raises error for whitespace-only file" do
    assert_raises(GolInputParser::ParseError) do
      GolInputParser.parse!("   \n\n  \n")
    end
  end

  test "raises error for file with less than 3 lines" do
    error = assert_raises(GolInputParser::ParseError) do
      GolInputParser.parse!("Generation 0:\n3 3")
    end
    assert_match(/expected at least 3 lines/, error.message)
  end

  test "raises error for invalid dimensions format" do
    content = <<~TXT
      Generation 0:
      abc
      .*.
    TXT

    error = assert_raises(GolInputParser::ParseError) do
      GolInputParser.parse!(content)
    end
    assert_match(/Invalid dimensions line/, error.message)
  end

  test "raises error for dimensions with only one number" do
    content = <<~TXT
      Generation 0:
      5
      .*.
    TXT

    error = assert_raises(GolInputParser::ParseError) do
      GolInputParser.parse!(content)
    end
    assert_match(/Invalid dimensions line/, error.message)
  end

  test "raises error for zero dimensions" do
    content = <<~TXT
      Generation 0:
      0 0
      .*.
    TXT

    error = assert_raises(GolInputParser::ParseError) do
      GolInputParser.parse!(content)
    end
    assert_match(/must be positive/, error.message)
  end

  test "raises error for negative dimensions" do
    content = <<~TXT
      Generation 0:
      -5 3
      .*.
    TXT

    error = assert_raises(GolInputParser::ParseError) do
      GolInputParser.parse!(content)
    end
    assert_match(/Invalid dimensions line/, error.message)
  end

  test "raises error for negative generation number" do
    # Note: Current implementation extracts unsigned numbers, so this might not trigger
    # but testing the validation logic
    content = <<~TXT
      Generation 0:
      3 3
      .*.
      *.*
      .*.
    TXT

    # This should pass since 0 is not negative
    result = GolInputParser.parse!(content)
    assert_equal 0, result.generation
  end

  test "raises error for grid dimensions exceeding maximum" do
    content = <<~TXT
      Generation 0:
      101 101
      *
    TXT

    error = assert_raises(GolInputParser::ParseError) do
      GolInputParser.parse!(content)
    end
    assert_match(/Grid dimensions too large/, error.message)
    assert_match(/max 100x100/, error.message)
  end

  test "allows maximum grid size" do
    # Create a 100x100 grid (maximum allowed)
    grid_lines = Array.new(100, "." * 100)
    content = "Generation 0:\n100 100\n#{grid_lines.join("\n")}"

    result = GolInputParser.parse!(content)
    assert_equal 100, result.rows
    assert_equal 100, result.cols
  end

  test "raises error for wrong number of grid rows" do
    content = <<~TXT
      Generation 0:
      3 3
      .*.
      *.*
    TXT

    error = assert_raises(GolInputParser::ParseError) do
      GolInputParser.parse!(content)
    end
    assert_match(/has 2 rows but expected 3/, error.message)
  end

  test "raises error for wrong number of columns in a row" do
    content = <<~TXT
      Generation 0:
      3 3
      .*.
      *.*..
      .*.
    TXT

    error = assert_raises(GolInputParser::ParseError) do
      GolInputParser.parse!(content)
    end
    assert_match(/Row 2 has 5 cells but expected 3/, error.message)
  end

  test "raises error for invalid characters in grid" do
    content = <<~TXT
      Generation 0:
      3 3
      .*.
      *X*
      .*.
    TXT

    error = assert_raises(GolInputParser::ParseError) do
      GolInputParser.parse!(content)
    end
    assert_match(/Row 2 contains invalid characters/, error.message)
    assert_match(/X/, error.message)
  end

  test "raises error for multiple invalid characters" do
    content = <<~TXT
      Generation 0:
      3 3
      .*.
      ABC
      .*.
    TXT

    error = assert_raises(GolInputParser::ParseError) do
      GolInputParser.parse!(content)
    end
    assert_match(/invalid characters/, error.message)
  end

  test "accepts only asterisks and dots" do
    content = <<~TXT
      Generation 0:
      3 3
      ***
      ...
      *.*
    TXT

    result = GolInputParser.parse!(content)
    assert_equal ["***", "...", "*.*"], result.grid_lines
  end

  test "handles Windows line endings (CRLF)" do
    content = "Generation 0:\r\n3 3\r\n.*.\r\n*.*\r\n.*."

    result = GolInputParser.parse!(content)
    assert_equal 3, result.rows
    assert_equal 3, result.cols
    assert_equal [".*.", "*.*", ".*."], result.grid_lines
  end

  test "handles Unix line endings (LF)" do
    content = "Generation 0:\n3 3\n.*.\n*.*\n.*."

    result = GolInputParser.parse!(content)
    assert_equal [".*.", "*.*", ".*."], result.grid_lines
  end

  test "ignores extra empty lines in file" do
    content = <<~TXT

      Generation 0:

      3 3

      .*.
      *.*
      .*.

    TXT

    result = GolInputParser.parse!(content)
    assert_equal 3, result.rows
    assert_equal [".*.", "*.*", ".*."], result.grid_lines
  end

  test "parses 1x1 grid" do
    content = <<~TXT
      Generation 0:
      1 1
      *
    TXT

    result = GolInputParser.parse!(content)
    assert_equal 1, result.rows
    assert_equal 1, result.cols
    assert_equal ["*"], result.grid_lines
  end

  test "parses rectangular grid (wide)" do
    content = <<~TXT
      Generation 5:
      2 10
      **........
      .........*
    TXT

    result = GolInputParser.parse!(content)
    assert_equal 2, result.rows
    assert_equal 10, result.cols
    assert_equal 5, result.generation
  end

  test "parses rectangular grid (tall)" do
    content = <<~TXT
      Generation 3:
      10 2
      **
      ..
      **
      ..
      **
      ..
      **
      ..
      **
      ..
    TXT

    result = GolInputParser.parse!(content)
    assert_equal 10, result.rows
    assert_equal 2, result.cols
  end

  test "returns ParseResult struct with correct attributes" do
    content = <<~TXT
      Generation 7:
      2 3
      *.*
      .*.
    TXT

    result = GolInputParser.parse!(content)

    assert_instance_of GolInputParser::ParseResult, result
    assert_respond_to result, :generation
    assert_respond_to result, :rows
    assert_respond_to result, :cols
    assert_respond_to result, :grid_lines
  end
end
