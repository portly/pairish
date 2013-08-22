require 'spec_helper'

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

  describe '#set_command' do
    before do
      @pty = Pssh::Pty.new
    end

    it 'uses the global value set to determine the command' do
      expect(Pssh).to receive(:command).and_return 'command'
      @pty.set_command
    end

    it 'defaults to creating a vanilla shell in zsh, sh, or bash' do
      allow(Pssh).to receive(:command).and_return('random')
      @pty.set_command
      expect(@pty.instance_variable_get(:@command)).to match(/.*sh$/)
    end

    context 'when Pssh.command is :tmux' do
      before do
        allow(Pssh).to receive(:command).and_return('tmux')
      end
      describe 'when ENV["TMUX"] is set' do
        before do
          allow(ENV).to receive(:[]).with('TMUX').and_return 'x,y,z'
          @pty.set_command
        end
        it 'uses the socket path from the variable' do
          expect(@pty.instance_variable_get(:@path)).to eq('x')
          expect(@pty.instance_variable_get(:@command)).to eq('tmux -S x attach')
        end
        it 'uses the attach command' do
          expect(@pty.instance_variable_get(:@command)).to match(/.*attach$/)
        end
        it 'flags that the socket exists already' do
          expect(@pty.existing?).to eq(true)
        end
      end
      describe 'when ENV["TMUX"] is not set' do
        before do
          allow(ENV).to receive(:[]).with('TMUX').and_return nil
          @pty.set_command
        end

        it 'uses the path set from the default_socket_path global' do
          expect(@pty.instance_variable_get(:@path)).to eq("/tmp/#{Pssh.default_socket_path}")
        end
        it 'uses the new command' do
          expect(@pty.instance_variable_get(:@command)).to match(/.*new$/)
        end
        it 'does not flag that the socket exists' do
          expect(@pty.new?).to eq(true)
        end
      end
    end

    context 'when Pssh.command is :screen' do
      before do
        allow(Pssh).to receive(:command).and_return('screen')
      end
      describe 'when ENV["STY"] is set' do
        before do
          allow(ENV).to receive(:[]).with('STY').and_return 'x'
          @pty.set_command
        end
        it 'uses the STY environment variable for the path' do
          expect(@pty.instance_variable_get(:@path)).to eq('x')
        end
        it 'flags that the socket exists already' do
          expect(@pty.existing?).to eq(true)
        end
      end
      describe 'when ENV["STY"] is not set' do
        before do
          allow(ENV).to receive(:[]).with('STY').and_return nil
          @pty.set_command
        end
        it 'uses the path set from the default_socket_path global' do
          expect(@pty.instance_variable_get(:@path)).to eq(Pssh.default_socket_path)
        end
        it 'does not flag that the socket exists' do
          expect(@pty.new?).to eq(true)
        end
      end
    end
  end

  describe '#write' do
    before do
      @pty = Pssh::Pty.new
      @write = double(:write)
      @pty.instance_variable_set(:@write, @write)
      @data = double(:data)
    end
    it 'writes data if io_mode includes "w"' do
      allow(Pssh).to receive(:io_mode).and_return 'rw'
      expect(@write).to receive(:write_nonblock).with(@data)
      @pty.write(@data)
    end
    it 'does not write data if io_mode does not include "w"' do
      allow(Pssh).to receive(:io_mode).and_return 'r'
      expect(@write).not_to receive(:write_nonblock).with(@data)
      @pty.write(@data)
    end
  end

end
