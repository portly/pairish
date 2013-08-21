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

        opts.on('--readonly', 'Only allow viewing the session, not writing.') do
          options[:io_mode] = 'r'
        end

        opts.on('-p PORT', '--port PORT', Integer, 'Set the port that Pssh will run on') do |port|
          options[:port] = port.to_i
        end

        opts.on('-s NAME', '--socket NAME', String, 'Set the socket that will be used for connecting (socket-name)') do |socket|
          options[:socket_path] = socket
        end

        opts.on( '-h', '--help', 'Display this help.' ) do
          puts opts
          exit
        end

      end

      @opts.parse!(args)

      options
    end

    def self.run(args=[])
      opts = parse_options(args)
      opts.each do |k,v|
        Pssh.send :"#{k}=", v
      end
      Pssh::Client.start
    end

  end
end

