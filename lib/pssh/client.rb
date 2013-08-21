module Pssh
  class Client

    def initialize
      @pty = Pssh.pty = Pssh::Pty.start
      @socket = Pssh.socket = Pssh::Socket.new
      @web = Pssh.web = Pssh::Web.new
      @app = Rack::Builder.new do
        map "/assets/" do
          run Rack::File.new "#{Pssh.base_path}/assets/"
        end
        map "/socket" do
          run Pssh.socket
        end
        map "/" do
          run Pssh.web
        end
      end
      Thin::Logging.silent = true
      if Pssh.pty.existing?
        @thread = Thread.new do
          @console = Console.new
        end
      end
      Rack::Handler::Thin.run @app, Port: Pssh.port
    end

    def self.start
      Pssh.client = @client = Client.new
    end

  end
end
