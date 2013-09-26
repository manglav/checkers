class InvalidMoveError < ArgumentError;end
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
  MOVES = {:white => [[-1, -1], [-1, 1]], :red => [[1, -1], [1, 1]]}
  attr_accessor :color, :pos, :king, :symbol
  attr_reader :board

  def initialize(color, pos, board)
    @color = color
    @pos = pos
    @king = false
    @symbol = "\u26C2"
    @board = board
  end

  def generate_moves
    if king
      return MOVES.values.flatten(1)
    else
      MOVES[color]
    end
  end

  def new_position(type, direction)
    if type == :slide
      [pos[0] + direction[0], pos[1] + direction[1]]
    elsif type == :jump
      [pos[0] + 2 * direction[0], pos[1] + 2 * direction[1]]
    end
  end


  def slide_moves
    possible_moves = []
    move_directions = generate_moves
    move_directions.each do |direction|
      location = new_position(:slide, direction)
      possible_moves << location if self.board.valid_move?(location)
    end
    possible_moves
  end

  def jumps_moves
    possible_moves = []
    move_directions = generate_moves

    move_directions.each do |direction|
      jump_location = new_position(:jump, direction)
      middle_location = new_position(:slide, direction)
      middle_piece = self.board.piece_at_location(middle_location)
      if jump_valid_move?(middle_piece, jump_location)
        possible_moves << jump_location
      end
    end
    possible_moves
  end

  def perform_moves!(move_sequence)
    #needs to take one slide, or one jump, or many jumps
    #assume move sequence is end_pos, next end_pos, etc...
    # [0,0] [1,1]  [2,2] [3,3]
    start_pos = self.pos
    # input can be [1,2] or [[1,2], [3,4]]
    if move_sequence[0].is_a?(Array) && move_sequence.count > 1
      # this means is a series of jumps
      puts "Series of jumps"
      move_sequence.each do |end_pos|
        self.board.perform_jump(start_pos, end_pos)
        start_pos = end_pos
      end
    else
      end_pos = move_sequence
      # this means it's either one jump or slide
      # check by checking if the index if off by 1 or 2
      delta = (start_pos[0] - end_pos[0]) % 2
      puts delta
      if delta == 0 # off by 2, jump
        self.board.perform_jump(start_pos, end_pos)
      else # slide
        self.board.perform_slide(start_pos, end_pos)
      end
    end
  end

  def jump_valid_move?(middle_piece, jump_location)
    self.board.valid_move?(jump_location) && middle_piece && middle_piece.color != self.color
  end

end

def setup
  b = Board.new
  b.pieces[11].pos = [4,4]
  b.pieces.delete(b.piece_at_location([1,3]))
  b.render
  b
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

  def piece_between_pos(start_pos, end_pos)
    piece_at_location([(start_pos[0] + end_pos[0])/2, (start_pos[1] + end_pos[1])/2])
  end

  def all_locations
    pieces.map {|piece| piece.pos}
  end

  def perform_slide(start_pos, end_pos)
    piece = piece_at_location(start_pos)
    raise InvalidMoveError.new "Bad Move" if !piece.slide_moves.include?(end_pos)
    piece.pos = end_pos if piece.slide_moves.include?(end_pos)
  end

  def perform_jump(start_pos, end_pos)
    piece = piece_at_location(start_pos)
    middle_piece = piece_between_pos(start_pos, end_pos)
    p piece.jumps_moves
    raise InvalidMoveError.new "Bad Move" if !piece.jumps_moves.include?(end_pos)
    piece.pos = end_pos
    pieces.delete(middle_piece)
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
