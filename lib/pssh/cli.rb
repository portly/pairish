module Pssh
  class CLI

    BANNER = <<-BANNER
    Usage: pssh [options]

    Description:

      Remote pair programming made easy by allowing access via a web
      browser.  Supports HTTP Basic Auth to handle users, and can be
      combined with tmux, screen, or just a plain shell.

    BANNER

    def self.parse_options(args)
      options = {}

      @opts = OptionParser.new do |opts|
        opts.banner = BANNER.gsub(/^ {4}/, '')

        opts.separator ''
        opts.separator 'Options:'

        opts.on('-p PORT', '--port PORT', Integer, 'Set the port that Pssh will run on') do |port|
          options[:port] = port.to_i
        end

        opts.on('-c PATH', '--command COMMAND', [:tmux, :screen, :shell], 'Set the tool that will be used to initialize the web session (tmux, screen, or shell)') do |command|
          options[:command] = command
        end

        opts.on('-s PATH', '--socket PATH', String, 'Set the socket that will be used for connecting (/path/to/socket)') do |socket|
          options[:socket] = socket
        end

        opts.on( '-h', '--help', 'Display this help.' ) do
          puts opts
          exit
        end

      end

      @opts.parse!(args)

      options
    end

    def self.run(args)
      opts = parse_options(args)
      Pssh.configure do |pssh|
        opts.each do |k,v|
          pssh.send :"#{k}=", v
        end
      end
      Pssh::Client.start
    end

  end
end

