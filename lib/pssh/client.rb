module Pssh
  class Client

    def initialize
      @pty = Pssh.pty = Pssh::Socket.new
      @web = Pssh.web = Pssh::WebConsole.new
      @app = Rack::Builder.new do
        map "/assets/" do
          run Rack::File.new "#{Pssh.base_path}/assets/"
        end
        map "/socket" do
          run Pssh.pty
        end
        map "/" do
          run Pssh.web
        end
      end
      Thread.new do
        @console = Console.new(pty: @pty, web: @web)
      end
      Thin::Logging.silent = true
      Rack::Handler::Thin.run @app, Port: Pssh.port
    end

    def self.start
      Pssh.client = @client = Client.new
    end

  end
end
