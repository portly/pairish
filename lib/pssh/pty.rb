module Pssh
  class Pty

    attr_reader :read
    #attr_reader :write
    attr_reader :stream
    attr_reader :pid

    attr_reader :path
    attr_reader :attach_cmd

    def initialize
      @stream = ''
      set_command
      clear_environment
      Thread.new do
        begin
          @read, @write, @pid = PTY.spawn(@command)
          @write.winsize = $stdout.winsize
          if new?
            system("clear")
            pssh = <<-BANNER
# [ pssh terminal ]
# Type `exit` to terminate this terminal.
BANNER
            $stdout.puts pssh
            Signal.trap(:WINCH) do
              resize!
            end
            system("stty raw -echo")
          end
          @active = true
          while @active do
            begin
              io = [@read]
              io << $stdin if new?
              rs, ws = IO.select(io)
              r = rs[0]
              while (data = r.read_nonblock(2048)) do
                if new? && r == $stdin
                  @write.write_nonblock data
                else
                  $stdout.write_nonblock data if new?
                  data.encode!('UTF-16', 'UTF-8', :invalid => :replace, :replace => '')
                  data.encode!('UTF-8', 'UTF-16')
                  if data.valid_encoding?
                    store data
                    Pssh.socket.write data
                  end
                end
              end
            rescue Exception => e
              if @active
                if e.is_a?(Errno::EAGAIN)
                  retry
                else
                  system("stty -raw echo") if new?
                  puts 'Terminating Pssh.'
                  Kernel.exit!
                  @active = false
                end
              end
            end
          end
        end
      end
    end

    def clear_environment
      ENV['TMUX'] = nil
      ENV['STY'] = nil
    end

    def new?
      !existing?
    end

    def existing?
      @existing_socket
    end

    def set_command
      case Pssh.command.to_sym
      when :tmux
        if ENV['TMUX']
          @path = ENV['TMUX'].split(',').first
          @existing_socket = true
          @command = "tmux -S #{@path} attach"
        else
          @path = "/tmp/#{Pssh.default_socket_path}"
          @command = "tmux -S #{@path} new"
        end
        @attach_cmd = "tmux -S #{@path} attach"
      when :screen
        if ENV['STY']
          @path = ENV['STY']
          @existing_socket = true
          @command = "screen -S #{@path} -X multiuser on && screen -x #{@path}"
        else
          @path = Pssh.default_socket_path
          @command = "screen -S #{@path}"
          puts @command
        end
        @attach_cmd = "screen -x #{@path}"
      else
        @path = nil
        @command = ENV['SHELL'] || (`which zsh` && 'zsh') || (`which sh` && 'sh') || 'bash'
      end
    end

    # Public: Writes to the open stream if they have access.
    #
    # Returns nothing.
    def write(data)
      @write.write_nonblock data if Pssh.io_mode['w']
    end

    # Public: Resizes the PTY session based on all the open
    # windows.
    #
    # Returns nothing.
    def resize!
      winsizes = Pssh.socket.sessions.values.map { |sess| sess[:winsize] }
      winsizes << $stdout.winsize if new?
      y = winsizes.map { |w| w[0] }.min
      x = winsizes.map { |w| w[1] }.min
      @write.winsize = [ y, x ]
    end

    # Public: Sends a message to the tmux or screen display notifying of a
    # new user that has connected.
    #
    # Returns nothing.
    def send_display_message(user)
      if @existing_socket
        case Pssh.command.to_sym
        when :tmux
          `tmux -S #{@path} display-message "#{user} has connected"`
        when :screen
          `screen -S #{@path} -X wall "#{user} has connected"`
        end
      end
    end

    # Internal: Store data to the stream so that when a new connection
    # is started we can send all that data and give them the visual.
    #
    # Returns nothing.
    def store(data)
      @stream << data
      @stream = @stream[-Pssh.cache_length..-1] if @stream.length > Pssh.cache_length
    end

  end
end
