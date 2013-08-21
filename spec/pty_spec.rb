require 'helper'

describe Pssh::Pty do

  describe '.start' do

    it 'starts the PTY process' do
      expect_any_instance_of(Pssh::Pty).to receive(:start_pty)
      Pssh::Pty.start
    end
  end

  describe '#initialize' do
    before do
      allow_any_instance_of(Pssh::Pty).to receive(:set_command)
      allow_any_instance_of(Pssh::Pty).to receive(:clear_environment)
      allow_any_instance_of(Pssh::Pty).to receive(:start_pty)
    end
    it 'sets the command used by PTY' do
      expect_any_instance_of(Pssh::Pty).to receive(:set_command)
      Pssh::Pty.new
    end
    it 'clears the environment to allow nesting tmux or screen' do
      expect_any_instance_of(Pssh::Pty).to receive(:clear_environment)
      Pssh::Pty.new
    end
  end

  describe '#start_pty' do
    before do
      @pty = Pssh::Pty.new
      @read = double(:read).as_null_object
      @write = double(:write).as_null_object
      @pid = double(:pid)
      allow($stdout).to receive(:puts)
      allow(Kernel).to receive(:exit!)
    end

    it 'creates a Thread' do
      expect(Thread).to receive(:new)
      @pty.start_pty
    end

    it 'spawns a PTY process' do
      expect(PTY).to receive(:spawn).and_return [@read, @write, @pid]
      allow(@pty).to receive(:new?).and_return false
      @pty.start_pty
      @pty.instance_variable_get(:@thread).join
    end

  end

  describe '#clear_environment' do
    before do
      @pty = Pssh::Pty.new
    end

    it 'unsets ENV["TMUX"] and ENV["STY"]' do
      expect(ENV).to receive(:[]=).with('TMUX',nil)
      expect(ENV).to receive(:[]=).with('STY',nil)
      @pty.clear_environment
    end
  end

end
