require 'helper'

describe Pssh do

  describe '.port' do
    it 'defaults to 8022' do
      expect(Pssh.port).to eq(8022)
    end
    it 'is assignable and uses the set value' do
      Pssh.port = 1234
      expect(Pssh.port).to eq(1234)
    end
  end

  describe '.io_mode' do
    it 'defaults to "rw"' do
      expect(Pssh.io_mode).to eq('rw')
    end
    it 'is assignable and uses the set value' do
      Pssh.io_mode = 'r'
      expect(Pssh.io_mode).to eq('r')
    end
  end

  describe '.cache_length' do
    it 'defaults to 16384' do
      expect(Pssh.cache_length).to eq(16384)
    end
    it 'is assignable and uses the set value' do
      Pssh.cache_length = 1
      expect(Pssh.cache_length).to eq(1)
    end
  end

  describe '.socket_prefix' do
    it 'defaults to "pssh"' do
      expect(Pssh.socket_prefix).to eq('pssh')
    end
    it 'is assignable and uses the set value' do
      Pssh.socket_prefix = 'session'
      expect(Pssh.socket_prefix).to eq('session')
    end
  end

  describe '.default_socket_path' do
    it 'models the format: socket_prefix-randomnumber' do
      allow(SecureRandom).to receive(:uuid).and_return 'random'
      allow(Pssh).to receive(:socket_prefix).and_return 'prefix'
      expect(Pssh.default_socket_path).to eq('prefix-random')
    end
  end

  describe '.command' do
    before do
      Pssh.command = nil
    end
    it 'returns :tmux if ENV["TMUX"] is set' do
      expect(ENV).to receive(:[]).with('TMUX').and_return true
      expect(Pssh.command).to eq(:tmux)
    end
    it 'returns :screen if ENV["STY"] is set' do
      allow(ENV).to receive(:[]).with('TMUX').and_return false
      allow(ENV).to receive(:[]).with('STY').and_return true
      expect(Pssh.command).to eq(:screen)
    end
    it 'defaults to :shell' do
      allow(ENV).to receive(:[]).and_return false
      expect(Pssh.command).to eq(:shell)
    end
  end

  describe '.create_sessions' do
    it 'stores the session to open_sessions' do
      expect(Pssh.open_sessions).to receive(:[]=)
      Pssh.create_session
    end
    it 'returns an id that has been randomly generated' do
      random = double(:id)
      expect(SecureRandom).to receive(:uuid).and_return random
      expect(Pssh.create_session).to be(random)
    end
    it 'saves the provided username to the hash' do
      username = double(:username)
      Pssh.open_sessions = {}
      Pssh.create_session username
      expect(Pssh.open_sessions.values).to eq([username])
    end
  end

end
