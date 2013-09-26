=begin

Notes

Board Class
  #perform_slide - needs to validate move
  #perform_jump  - needs to validate move, remove jumped piece

  illegal move should raise Invalid move error

Piece Class
  # slide_moves
  # jumps_moves
Game Class

=end

class Piece
  attr_accessor :color, :king

  def initialize(color, pos)
    @color = color
    @pos = pos
    @king = false
    @symbol = @color == :red ? "26C0" : "26C2"
  end

end

class Board

  def initialize
    @game_board = build_board
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
      Piece.new(:red, pos)
    end
    black_pieces = black.map do |pos|
      Piece.new(:black, pos)
    end
    red_pieces + black_pieces
  end

  def render

  end
end




    # 8 x 8 board, pieces are on first three rows, alternating
