require 'spec_helper'
require_relative '../proxxlike'

RSpec.describe Proxxlike do
  describe 'initialized configuration' do
    it { expect(subject.instance_variable_get(:@selected)).to eq([0, 0]) }
    it { expect(subject.instance_variable_get(:@size)).to eq(20) }
    it { expect(subject.instance_variable_get(:@difficulty)).to eq(1) }
    it { expect(subject.instance_variable_get(:@board)).to eq([]) }
  end

  describe '#reset_settings' do
    it 'resets settings' do
      subject.instance_variable_set(:@selected, [1, 1])
      subject.instance_variable_set(:@opened, [1, 1])
      subject.reset_settings
      expect(subject.instance_variable_get(:@selected)).to eq([0, 0])
      expect(subject.instance_variable_get(:@opened)).to eq([])
    end
  end

  describe '#generate_board' do
    it 'generates board' do
      subject.instance_variable_set(:@size, 2)
      subject.generate_board(2)
      expect(subject.instance_variable_get(:@board)).to eq([[0, 0], [0, 0]])
    end
  end

  describe '#generate_holes' do
    it 'generates holes with difficulty 1' do
      subject.instance_variable_set(:@difficulty, 1)
      subject.generate_board(10)

      expect(subject.instance_variable_get(:@board).flatten).not_to include('x')

      subject.generate_holes

      expect(subject.instance_variable_get(:@board).flatten).to include('x')
      expect(subject.instance_variable_get(:@board).flatten.count('x')).to be_between(1, 40)
    end

    it 'generates holes with difficulty 3' do
      subject.instance_variable_set(:@difficulty, 3)
      subject.generate_board(10)

      expect(subject.instance_variable_get(:@board).flatten).not_to include('x')

      subject.generate_holes

      expect(subject.instance_variable_get(:@board).flatten).to include('x')
      expect(subject.instance_variable_get(:@board).flatten.count('x')).to be_between(20, 60)
    end

    it 'generates holes with difficulty 5' do
      subject.instance_variable_set(:@difficulty, 5)
      subject.generate_board(10)

      expect(subject.instance_variable_get(:@board).flatten).not_to include('x')

      subject.generate_holes

      expect(subject.instance_variable_get(:@board).flatten).to include('x')
      expect(subject.instance_variable_get(:@board).flatten.count('x')).to be_between(40, 80)
    end

    it 'generates holes with difficulty 7' do
      subject.instance_variable_set(:@difficulty, 7)
      subject.generate_board(10)

      expect(subject.instance_variable_get(:@board).flatten).not_to include('x')

      subject.generate_holes

      expect(subject.instance_variable_get(:@board).flatten).to include('x')
      expect(subject.instance_variable_get(:@board).flatten.count('x')).to be_between(60, 100)
    end
  end

  describe '#calculate_holes' do
    it 'calculates holes basic check' do
      subject.instance_variable_set(:@board, [
        [0, 0, 'x'],
        [0, 0, 'x'],
        ['x', 0, 0]
      ])
      subject.calculate_holes

      expect(subject.instance_variable_get(:@board)).to eq([
        [0, 2, 'x'],
        [1, 3, 'x'],
        ['x', 2, 1]
      ])
    end

    it 'calculates holes advanced check' do
      subject.instance_variable_set(:@board, [
        [0, 0, 'x', 0, 0],
        [0, 0, 'x', 0, 0],
        [0, 0, 0, 0, 'x'],
        [0, 'x', 0, 0, 'x'],
        ['x', 'x', 0, 0, 'x']
      ])
      subject.calculate_holes

      expect(subject.instance_variable_get(:@board)).to eq([
        [0, 2, 'x', 2, 0],
        [0, 2, 'x', 3, 1],
        [1, 2, 2, 3, 'x'],
        [3, 'x', 2, 3, 'x'],
        ['x', 'x', 2, 2, 'x']
      ])
    end
  end

  describe '#render_board' do
    it 'clears screen' do
      expect(subject).to receive(:system).with('clear').and_return(true)
      expect { subject.render_board }.to output(/Use arrow keys/).to_stdout
    end

    it 'shows help message' do
      allow(subject).to receive(:system).with('clear')

      subject.instance_variable_set(:@board, [
        [0,   0,  1, 'x'],
        [1,   1,  1,  1],
        ['x', 2,  0,  0],
        ['x', 2,  0,  0]
      ])

      subject.check_cell(3, 3)

      expect { subject.render_board }.to output(/Use arrow keys to navigate and space\/enter to open cell\nTo exit round press Ctrl\+C, to exit completly press that twice/).to_stdout
    end

    it 'tries to render each cell' do
      allow(subject).to receive(:system).with('clear').and_return(true)

      subject.instance_variable_set(:@board, [
        [0, 0, 'x'],
        [0, 0, 'x'],
        ['x', 0, 0]
      ])

      expect(subject).to receive(:render_cell).exactly(9).times
      expect { subject.render_board }.to output(/Use arrow keys/).to_stdout
    end

    it 'tries to render each cell' do
      allow(subject).to receive(:system).with('clear').and_return(true)

      subject.instance_variable_set(:@board, [
        [0, 0, 'x'],
        [0, 0, 'x'],
        ['x', 0, 0]
      ])

      expect(subject).to receive(:render_cell_value).with(0, 0, true).and_return('x')
      expect(subject).to receive(:render_cell_value).with(0, 1, true).and_return('x')
      expect(subject).to receive(:render_cell_value).with(0, 2, true).and_return('x')
      expect(subject).to receive(:render_cell_value).with(1, 0, true).and_return('x')
      expect(subject).to receive(:render_cell_value).with(1, 1, true).and_return('x')
      expect(subject).to receive(:render_cell_value).with(1, 2, true).and_return('x')
      expect(subject).to receive(:render_cell_value).with(2, 0, true).and_return('x')
      expect(subject).to receive(:render_cell_value).with(2, 1, true).and_return('x')
      expect(subject).to receive(:render_cell_value).with(2, 2, true).and_return('x')

      expect { subject.render_board(true) }.to output(/Use arrow keys/).to_stdout
    end
  end

  describe '#check_cell' do
    it 'returns x on hole' do
      subject.instance_variable_set(:@board, [
        [0, 0, 'x'],
        [0, 0, 'x'],
        ['x', 0, 0]
      ])

      expect(subject.check_cell(0, 2)).to eq('x')
    end
  end

  describe '#start' do
    it 'start' do
      allow(subject).to receive(:read_char).and_return("\u0003")

      expect(subject).to receive(:render_board).with(no_args).exactly(2).times
      expect(subject).to receive(:render_board).with(true)

      expect { subject.start }.to output(/You lose!/).to_stdout
    end
  end
end
