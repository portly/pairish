require 'spec_helper'

describe Pssh::Console do

  before do
    allow_any_instance_of(Pssh::Console).to receive(:print)
  end

  describe '#initialize' do

    it 'loops with Readline to capture input' do
      expect(Readline).to receive(:readline)
      Pssh::Console.new
    end

  end

  describe "commands accepted by Readline" do

    describe '"help" is typed' do
      before do
        allow(Readline).to receive(:readline).and_return('help',false)
      end

      it 'prints the banner' do
        expect($stdout).to receive(:puts).with(Pssh::Console::BANNER.gsub(/^ {6}/,''))

        Pssh::Console.new
      end
    end

    describe '"exit" is typed' do
      before do
        allow(Readline).to receive(:readline).and_return('exit',false)
      end
      it 'kills all the open sessions' do
        socket = double(:socket)
        expect(Pssh).to receive(:socket).and_return socket
        expect(socket).to receive(:kill_all_sessions)
        allow(Kernel).to receive(:exit!)
        Pssh::Console.new
      end
      it 'kills the current running program' do
        socket = double(:socket).as_null_object
        allow(Pssh).to receive(:socket).and_return socket
        expect(Kernel).to receive(:exit!)
        Pssh::Console.new
      end
    end

    describe '"info" is typed' do
      before do
        allow(Readline).to receive(:readline).and_return('info',false)
        allow($stdout).to receive(:puts)
      end

      context 'PTY is attached to a tmux or screen session' do
        it 'displays the command to attach to that session' do
          pty = double(:pty)
          allow(pty).to receive(:path).and_return true
          expect(Pssh).to receive(:pty).at_least(:once).and_return pty
          expect(pty).to receive(:attach_cmd)

          Pssh::Console.new
        end
      end
    end

    describe '"list" is typed' do
      before do
        allow(Readline).to receive(:readline).and_return('list',false)
        allow($stdout).to receive(:puts)
      end

      it 'lists the current socket sessions' do
        socket = double(:socket)
        expect(socket).to receive(:sessions).and_return {}
        expect(Pssh).to receive(:socket).and_return socket

        Pssh::Console.new
      end
    end

    describe '"kill-session" is typed' do
      before do
        allow($stdout).to receive(:puts)
      end

      context '--all is typed' do
        before do
          allow(Readline).to receive(:readline).and_return('kill-sessions --all',false)
        end
        it 'kills all the open sessions' do
          socket = double(:socket)
          expect(Pssh).to receive(:socket).and_return socket
          expect(socket).to receive(:kill_all_sessions)
          Pssh::Console.new
        end
      end

      context 'a specific session is supplied' do
        before do
          allow(Readline).to receive(:readline).and_return('kill-session sessionid',false)
          @sessions = {
            'nope' => 'not this one',
            'sessionid' => double(:session).as_null_object
          }
        end
        it 'kills the selected session' do
          socket = double(:socket)
          sess = double(:session_socket)
          expect(Pssh).to receive(:socket).at_least(:once).and_return socket
          expect(socket).to receive(:sessions).at_least(:once).and_return @sessions
          expect(@sessions['sessionid']).to receive(:[]).with(:socket).and_return sess
          expect(sess).to receive(:close!)
          Pssh::Console.new
        end
      end
    end

    describe '#completion_proc' do
      before do
        allow(Readline).to receive(:readline).and_return false
      end

      it 'returns a proc' do
        expect(Pssh::Console.new.completion_proc).to be_kind_of(Proc)
      end
    end

  end

end
