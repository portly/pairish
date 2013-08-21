require 'helper'

describe Pssh::Client do

  describe '#initialize' do
    before do
      @stubbed_pty = double(:pty)
      allow(@stubbed_pty).to receive(:existing?).and_return false
      allow(Rack::Handler::Thin).to receive(:run)
    end

    it 'starts up a PTY' do
      allow(Pssh::Socket).to receive(:new)
      allow(Pssh::Web).to receive(:new)
      allow(Rack::Builder).to receive(:new)

      expect(Pssh::Pty).to receive(:new).and_return @stubbed_pty
      expect(Pssh).to receive(:pty=).with(@stubbed_pty)
      allow(Pssh).to receive(:pty).and_return @stubbed_pty

      Pssh::Client.new
    end

    it 'starts up a WebSocket' do
      allow(Pssh::Pty).to receive(:new).and_return(@stubbed_pty)
      allow(Pssh::Web).to receive(:new)
      allow(Rack::Builder).to receive(:new)

      socket = double(:socket).as_null_object
      expect(Pssh::Socket).to receive(:new).and_return socket
      expect(Pssh).to receive(:socket=).with(socket)
      allow(Pssh).to receive(:socket).and_return socket

      Pssh::Client.new
    end

    it 'starts up a Web App' do
      allow(Pssh::Pty).to receive(:new).and_return(@stubbed_pty)
      allow(Pssh::Socket).to receive(:new)
      allow(Rack::Builder).to receive(:new)

      web = double(:web).as_null_object
      expect(Pssh::Web).to receive(:new).and_return web
      expect(Pssh).to receive(:web=).with(web)
      allow(Pssh).to receive(:web).and_return web

      Pssh::Client.new
    end

    it 'creates another thread for a console' do
      stubbed_pty = double(:pty)
      allow(stubbed_pty).to receive(:existing?).and_return true
      allow(Pssh::Pty).to receive(:new).and_return(stubbed_pty)
      allow(Pssh::Web).to receive(:new)
      allow(Pssh::Socket).to receive(:new)
      allow(Rack::Builder).to receive(:new)
      expect(Thread).to receive(:new)

      Pssh::Client.new
    end

    it 'creates a console' do
      stubbed_pty = double(:pty)
      allow(stubbed_pty).to receive(:existing?).and_return true
      allow(Pssh::Pty).to receive(:new).and_return(stubbed_pty)
      allow(Pssh::Web).to receive(:new)
      allow(Pssh::Socket).to receive(:new)
      allow(Rack::Builder).to receive(:new)
      expect(Pssh::Console).to receive(:new)

      client = Pssh::Client.new
      client.instance_variable_get(:@thread).join
    end

    it 'starts a Thin server to run everything' do
      port = double(:port)
      app = double(:app)
      allow(Pssh).to receive(:port).and_return port
      allow(Pssh::Pty).to receive(:new).and_return(@stubbed_pty)
      allow(Pssh::Web).to receive(:new)
      allow(Pssh::Socket).to receive(:new)
      allow(Rack::Builder).to receive(:new).and_return(app)

      expect(Rack::Handler::Thin).to receive(:run).with(app, Port: port)

      Pssh::Client.new
    end

  end

  describe '.start' do
    it 'creates a new Client' do
      expect(Pssh::Client).to receive(:new)
      Pssh::Client.start
    end
    it 'stores the client to the Pssh class' do
      client = double(:client)
      allow(Pssh::Client).to receive(:new).and_return client
      expect(Pssh).to receive(:client=).with(client)
      Pssh::Client.start
    end
  end

end


