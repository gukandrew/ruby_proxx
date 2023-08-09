require 'io/console'

# configuration
@debug_mode = false
@size = 20

@selected = [0, 0] # [y, x]
@opened = []

def main
  start

  puts 'Press Y to restart or any other key to exit'
  while key = read_char
    exit if key == "\u0003"

    case key
    when "Y", "y"
      main
    else
      exit
    end
  end
end

def start
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
    when "\r" # enter
      round_ended = check_cell == 'x'
    end

    if round_ended
      render_board(true)
      puts 'You lose!'
      break
    else
      render_board
    end
  end
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
  system('clear')

  @board.each_with_index do |row, y|
    if y == 0
      printf("%6s", ' ')
      row.length.times { |n| printf("%4s", n + 1) }

      printf("\n%6s", ' ')
      print sprintf("%4s", '-') * row.length
      print("\n")
    end

    print printf("%4i |", y + 1)

    row.each_with_index do |cell, x|
      render_cell(y, x, force_show)
    end

    print "\n"
  end
  print "\nTo round press Ctrl+C, to exit completly press that twice\n"
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
      @board[y][x] = 'x' if rand(10) < 2
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

def update_nearest_cells(y, x)
  rows_n = @board.length - 1

  if y > 0 && @board[y - 1][x] != 'x'
    @board[y - 1][x] += 1
  end
  if y < rows_n && @board[y + 1][x] != 'x'
    @board[y + 1][x] += 1
  end
  if x > 0 && @board[y][x - 1] != 'x'
    @board[y][x - 1] += 1
  end
  if x < rows_n && @board[y][x + 1] != 'x'
    @board[y][x + 1] += 1
  end
  if y > 0 && x > 0 && @board[y - 1][x - 1] != 'x'
    @board[y - 1][x - 1] += 1
  end
  if y > 0 && x < rows_n && @board[y - 1][x + 1] != 'x'
    @board[y - 1][x + 1] += 1
  end
  if y < rows_n && x > 0 && @board[y + 1][x - 1] != 'x'
    @board[y + 1][x - 1] += 1
  end
  if y < rows_n && x < rows_n && @board[y + 1][x + 1] != 'x'
    @board[y + 1][x + 1] += 1
  end
end

def check_cell
  y = @selected[0]
  x = @selected[1]

  if @board[y][x] == 'x'
    return 'x'
  elsif @board[y][x] == 0
    open_zero_cells(y, x)
  end

  @opened << [y,x]
end

def open_zero_cells(y, x, processed = [])
  rows_n = @board.length - 1

  @opened << [y,x]
  processed << [y,x]

  if y > 0 && @board[y - 1][x] == 0 && !@opened.include?([y - 1, x]) && !processed.include?([y - 1, x])
    open_zero_cells(y - 1, x, processed)
  end
  if y < rows_n && @board[y + 1][x] == 0 && !@opened.include?([y + 1, x]) && !processed.include?([y + 1, x])
    open_zero_cells(y + 1, x, processed)
  end
  if x > 0 && @board[y][x - 1] == 0 && !@opened.include?([y, x - 1]) && !processed.include?([y, x - 1])
    open_zero_cells(y, x - 1, processed)
  end
  if x < rows_n && @board[y][x + 1] == 0 && !@opened.include?([y, x + 1]) && !processed.include?([y, x + 1])
    open_zero_cells(y, x + 1, processed)
  end
  if y > 0 && x > 0 && @board[y - 1][x - 1] == 0 && !@opened.include?([y - 1, x - 1]) && !processed.include?([y - 1, x - 1])
    open_zero_cells(y - 1, x - 1, processed)
  end
  if y > 0 && x < rows_n && @board[y - 1][x + 1] == 0 && !@opened.include?([y - 1, x + 1]) && !processed.include?([y - 1, x + 1])
    open_zero_cells(y - 1, x + 1, processed)
  end
  if y < rows_n && x > 0 && @board[y + 1][x - 1] == 0 && !@opened.include?([y + 1, x - 1]) && !processed.include?([y + 1, x - 1])
    open_zero_cells(y + 1, x - 1, processed)
  end
  if y < rows_n && x < rows_n && @board[y + 1][x + 1] == 0 && !@opened.include?([y + 1, x + 1]) && !processed.include?([y + 1, x + 1])
    open_zero_cells(y + 1, x + 1, processed)
  end
end

main
