require 'colorize'
require 'YAML'
require 'debugger'

class InvalidMoveError < ArgumentError; end

class Piece
  MOVES = {
    :white => [[-1, -1], [-1, 1]],
    :red => [[1, -1], [1, 1]]
  }

  attr_accessor :color, :pos, :king, :symbol
  attr_reader :board

  def initialize(color, pos, board)
    @color = color
    @pos = pos
    @king = false
    @symbol = "P"
    @board = board
  end

  def generate_moves
    if king
      MOVES.values.flatten(1)
    else
      MOVES[color]
    end
  end

  def check_and_make_king
    if (self.color == :red && self.pos[0] == 7) || (self.color == :white && self.pos[0] == 0)
      self.king = true
      self.symbol = "K"
    end
  end

  def new_position(type, direction)
    case type
    when :slide
      [pos[0] + direction[0], pos[1] + direction[1]]
    when :jump
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

  def valid_move_seq?(move_sequence)
    board_dup = YAML::load(self.board.to_yaml)
    begin
      duped_piece = board_dup.piece_at_location(self.pos)
      duped_piece.perform_moves!(move_sequence)
    rescue InvalidMoveError => e
      self.board.errors << e.message
      false
    else
      true
    end
  end

  def perform_moves(move_sequence)
    if valid_move_seq?(move_sequence)
      puts "it is valid"
      perform_moves!(move_sequence)
    else
      false
    end
  end

  def perform_moves!(move_sequence)
    ## Assume move_sequence is always an array of arrays. [[]], or [[1,2]] or [[1,2],[3,4]]
    start_pos = self.pos
    delta = (start_pos[0] - move_sequence[0][0]) % 2
    if delta == 0
      move_sequence.each do |end_pos|
        self.board.perform_jump(start_pos, end_pos)
        start_pos = end_pos
      end
      raise InvalidMoveError.new "You have more possible moves" if self.jumps_moves.any?
    else
      self.board.perform_slide(start_pos, move_sequence[0])
    end
  end

  def jump_valid_move?(middle_piece, jump_location)
    self.board.valid_move?(jump_location) &&
    middle_piece                          &&
    middle_piece.color != self.color
  end

end

class Board
  attr_accessor :pieces, :errors

  def initialize
    @pieces = build_board
    @errors = []
  end

  def dup
    dup = Board.new
    self.pieces do |piece|
      dup.pieces << piece.dup
    end
  end

  def valid_move?(pos)
    pos[0].between?(0,7) &&
    pos[1].between?(0,7) &&
    !all_locations.include?(pos)
  end

  def piece_at_location(location)
    pieces.select {|piece| piece.pos == location}[0]
  end

  def piece_between_pos(start_pos, end_pos)
    pos = [(start_pos[0] + end_pos[0])/2, (start_pos[1] + end_pos[1])/2]
    piece_at_location(pos)
  end

  def all_locations
    pieces.map {|piece| piece.pos}
  end

  def perform_slide(start_pos, end_pos)
    piece = piece_at_location(start_pos)
    raise InvalidMoveError.new "Bad Move" if !piece.slide_moves.include?(end_pos)
    piece.pos = end_pos
    piece.check_and_make_king
  end

  def perform_jump(start_pos, end_pos)
    piece = piece_at_location(start_pos)
    middle_piece = piece_between_pos(start_pos, end_pos)
    p piece.jumps_moves
    raise InvalidMoveError.new "Bad Move" if !piece.jumps_moves.include?(end_pos)
    piece.pos = end_pos
    pieces.delete(middle_piece)
    piece.check_and_make_king
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

  # def to_s
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

class Game
  attr_accessor :board

  def initialize
    @board = Board.new
  end

  def play
    until game_over?
      @board.render
      make_move
    end
  end

  def make_move
    puts "Give moving piece location"
    input = gets.chomp
    p start_pos = input.scan(/[01234567]/).map {|s| s.to_i }
    puts "Give move sequence"
    input = gets.chomp
    p move_sequence = input.scan(/[01234567]/).map {|s| s.to_i }.each_slice(2).to_a
    if board.piece_at_location(start_pos).perform_moves(move_sequence)
    else
      puts board.errors.pop
    end
  end

  def game_over?
  end

end
    # 8 x 8 board, pieces are on first three rows, alternating
