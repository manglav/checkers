=begin

Notes

Board Class
  #perform_slide - needs to validate move
  #perform_jump  - needs to validate move, remove jumped piece

  illegal move should raise Invalid move error

Piece Class
  # slide_moves - lists possible moves
  # jumps_moves - lists possible moves
Game Class

=end
require 'colorize'
class Piece
  MOVES_WHITE = [[-1, -1], [-1, 1]]
  MOVES_RED = [[1, -1], [1, 1]]
  attr_accessor :color, :pos, :king, :symbol
  attr_reader :board

  def initialize(color, pos, board)
    @color = color
    @pos = pos
    @king = false
    @symbol = "\u26C2"
    @board = board
  end

  def slide_moves
    possible_moves = []
    move_directions = []
    move_directions.concat(MOVES_WHITE) if color == :white || king == true
    move_directions.concat(MOVES_RED) if color == :red || king == true
    move_directions.each do |direction|
      location = [pos[0] + direction[0], pos[1] + direction[1]]
      possible_moves << location if self.board.valid_move?(location)
    end
    possible_moves
  end

  def jumps_moves
    possible_moves = []
    move_directions = []
    move_directions.concat(MOVES_WHITE) if color == :white || king == true
    move_directions.concat(MOVES_RED) if color == :red || king == true
    #dry this out
    move_directions.each do |direction|
      jump_location = [pos[0] + 2 * direction[0], pos[1] + 2 * direction[1]]
      middle_location = [pos[0] + direction[0], pos[1] + direction[1]]
      middle_piece = self.board.piece_at_location(middle_location)
      if self.board.valid_move?(jump_location) && middle_piece && middle_piece.color != self.color
        possible_moves << jump_location
      end

    end
    possible_moves
  end

end

class Board
  attr_accessor :pieces
  def initialize
    @pieces = build_board
  end

  def valid_move?(pos)
    return false if !pos[0].between?(0,7) && !pos[1].between?(0,7)
    return false if all_locations.include?(pos)
    true
  end

  def piece_at_location(location)
    pieces.select {|piece| piece.pos == location}[0]

  end

  def all_locations
    pieces.map {|piece| piece.pos}
  end

  def perform_slide
  end

  def perform_jump
  end

  def build_board
    results = []
    even_row_cord = [0, 2, 6]
    odd_row_cord = [1, 5, 7]

    even_col_cord = [0, 2, 4, 6]
    odd_col_cord = [1, 3, 5, 7]

    even_row_cord.each do |i|
      even_col_cord.each do |j|
        results << [i,j]
      end
    end

    odd_row_cord.each do |i|
      odd_col_cord.each do |j|
        results << [i,j]
      end
    end
    red = results.sort[0..11]
    black = results.sort[12..-1]

    red_pieces = red.map do |pos|
      Piece.new(:red, pos, self)
    end
    black_pieces = black.map do |pos|
      Piece.new(:white, pos, self)
    end
    red_pieces + black_pieces
  end

  def render
    print_array = Array.new(8) { Array.new(8) }

    @pieces.each do |piece|
      print_array[piece.pos[0]][piece.pos[1]] = piece.symbol.colorize(piece.color)
    end

    print "     "
    puts [0, 1, 2, 3, 4, 5, 6, 7].join("    ")

    print_array.each_with_index do |row, index|
      print "#{index}  "
      row.each do |tile|
        if tile.nil?
          print "|    " if tile.nil?
        else
          print "| #{tile}  "
        end
      end
      puts "|"
      puts "   -----------------------------------------"
    end
    nil
  end
end




    # 8 x 8 board, pieces are on first three rows, alternating
