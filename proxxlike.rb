# frozen_string_literal: true

require 'io/console'

class Proxxlike
  def initialize
    # configuration
    @debug_mode = false
    @size = 20
    @difficulty = 1 # 1-7 represents holes freequency (1 - easy, 7 - hard)

    @board = []
    @opened = []
    @selected = [0, 0] # [y, x]
  end

  def run
    start

    puts 'Press Y, Enter or Space to restart or any other key to exit'
    while key = read_char
      exit if key == "\u0003"

      case key
      when "Y", "y", "\r", " "
        run
      else
        exit
      end
    end
  end

  def reset_settings
    @selected = [0, 0]
    @opened = []
  end

  def start
    reset_settings
    generate_board(@size)
    generate_holes
    calculate_holes
    render_board

    while key = read_char
      round_ended = false

      case key
      when "\u0003"
        round_ended = true
      when "\e[D" # left
        @selected[1] -= 1 if @selected[1] > 0
      when "\e[C" # right
        @selected[1] += 1 if @selected[1] < @board.length - 1
      when "\e[A" # up
        @selected[0] -= 1 if @selected[0] > 0
      when "\e[B" # down
        @selected[0] += 1 if @selected[0] < @board.length - 1
      when "\r", " " # enter or space
        round_ended = check_cell(@selected[0], @selected[1]) == 'x'
      end

      render_board

      if check_win
        render_board(true)
        puts 'You win!'
        break
      elsif round_ended
        render_board(true)
        puts 'You lose!'
        break
      end
    end
  end

  def check_win
    @board.map { |row| row.count { |v| v != 'x' } }.sum == @opened.count
  end

  def generate_board(n)
    @board = []
    n.times do
      @board << n.times.map { |_i| 0 }
    end
    @board
  end

  # see: https://gist.github.com/acook/4190379
  def read_char
    STDIN.echo = false
    STDIN.raw!

    input = STDIN.getc.chr
    if input == "\e" then
      input << STDIN.read_nonblock(3) rescue nil
      input << STDIN.read_nonblock(2) rescue nil
    end
  ensure
    STDIN.echo = true
    STDIN.cooked!

    return input
  end

  def render_board(force_show = false)
    system('clear') unless @debug_mode

    @board.each_with_index do |row, y|
      render_first_line(row.length) if y == 0
      render_first_column(y)

      render_cells(y, row, force_show)

      print "\n"
    end
    print "\nUse arrow keys to navigate and space/enter to open cell\n"
    print "To exit round press Ctrl+C, to exit completly press that twice\n"
  end

  def render_first_line(width)
    printf("%6s", ' ')
    width.times { |n| printf("%4s", n + 1) }

    printf("\n%6s", ' ')
    print sprintf("%4s", '-') * width
    print("\n")
  end

  def render_first_column(y)
    print printf("%4i |", y + 1)
  end

  def render_cells(y, row, force_show = false)
    row.each_with_index do |cell, x|
      render_cell(y, x, force_show)
    end
  end

  # for colors reference see: https://stackoverflow.com/a/16363159/10175256
  def render_cell(y, x, force_show = false)
    if @selected[0] == y && @selected[1] == x
      printf("\e[42m%s\e[0m", render_cell_value(y, x, @debug_mode || force_show))
    elsif force_show == true && @board[y][x] == 'x'
      printf("\e[41m%s\e[0m", render_cell_value(y, x, force_show))
    elsif @opened.include?([y,x])
      printf("\e[43m%s\e[0m", render_cell_value(y, x, true))
    else
      printf("%s", render_cell_value(y, x, force_show))
    end
  end

  def render_cell_value(y, x, force_show = false)
    value = ''
    value = @board[y][x] if force_show == true || @opened.include?([y,x])

    sprintf("%4s", value)
  end

  def generate_holes
    @board.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        @board[y][x] = 'x' if rand(10) < @difficulty
      end
    end
  end

  def calculate_holes
    @board.each_with_index do |row, y|
      row.each_with_index do |cell, x|
        next if @board[y][x] != 'x'

        update_nearest_cells(y, x)
      end
    end
  end

  def update_nearest_cells(y, x, parent_cell = true)
    rows_n = @board.length - 1

    @board[y][x] += 1 if @board[y][x] != 'x'

    return if parent_cell == false

    if y > 0 # up
      update_nearest_cells(y - 1, x, false)
    end
    if y < rows_n # down
      update_nearest_cells(y + 1, x, false)
    end
    if x > 0 # left
      update_nearest_cells(y, x - 1, false)
    end
    if x < rows_n # right
      update_nearest_cells(y, x + 1, false)
    end
    if y > 0 && x > 0 # up left
      update_nearest_cells(y - 1, x - 1, false)
    end
    if y > 0 && x < rows_n # up right
      update_nearest_cells(y - 1, x + 1, false)
    end
    if y < rows_n && x > 0 # down left
      update_nearest_cells(y + 1, x - 1, false)
    end
    if y < rows_n && x < rows_n # down right
      update_nearest_cells(y + 1, x + 1, false)
    end
  end

  def check_cell(y, x)
    if @board[y][x] == 'x'
      return 'x'
    elsif @board[y][x] == 0
      open_zero_cells(y, x)
    end

    open_cell(y, x)
  end

  def open_cell(y, x)
    @opened << [y,x] unless @opened.include?([y,x])
  end

  def open_zero_cells(y, x, previous_value = 0, processed = [])
    value = @board[y][x]

    return if @opened.include?([y,x]) || processed.include?([y,x]) || previous_value != 0

    rows_n = @board.length - 1

    open_cell(y, x)
    processed << [y,x]

    if y > 0 # up
      open_zero_cells(y - 1, x, value, processed)
    end
    if y < rows_n # down
      open_zero_cells(y + 1, x, value, processed)
    end
    if x > 0 # left
      open_zero_cells(y, x - 1, value, processed)
    end
    if x < rows_n # right
      open_zero_cells(y, x + 1, value, processed)
    end
    if y > 0 && x > 0 # up left
      open_zero_cells(y - 1, x - 1, value, processed)
    end
    if y > 0 && x < rows_n # up right
      open_zero_cells(y - 1, x + 1, value, processed)
    end
    if y < rows_n && x > 0 # down left
      open_zero_cells(y + 1, x - 1, value, processed)
    end
    if y < rows_n && x < rows_n # down right
      open_zero_cells(y + 1, x + 1, value, processed)
    end
  end

end
