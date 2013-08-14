module Pssh
  class Socket < Rack::WebSocket::Application

    attr_accessor :sessions
    attr_accessor :path
    attr_accessor :attach_cmd

    def initialize(opts={})
      super

      # set up empty variables
      @sessions = {}
      @killed_sessions = []
      @existing_socket = false

      self.send Pssh.command.to_sym
    end

    def tmux
      if ENV['TMUX']
        @path = ENV['TMUX'].split(',').first
        @existing_socket = true
        @command = "tmux -S #{@path} attach"
      else
        @path = Pssh.default_socket_path
        @command = "tmux -S #{@path} new"
      end
      @attach_cmd = "tmux -S #{@path} attach"
    end

    def screen
      if ENV['STY']
        @path = ENV['STY']
        @existing_socket = true
        @command = "screen -S #{@path} -X multiuser on && screen -x #{@path}"
      else
        @path = Pssh.default_socket_path
        @command = "screen -m -S #{@path}"
      end
      @attach_cmd = "screen -x #{@path}"
    end

    def shell
      @path = nil
      @command = 'sh'
    end

    def params(env)
      Hash[env['QUERY_STRING'].split('&').map { |e| e.split '=' }]
    end

    def on_open(env)
      uuid = @uuid = params(env)['uuid']
      if @killed_sessions.include? uuid
        # this session has been killed from the console and shouldn't be
        # restarted
        close_websocket and return
      end
      if @sessions[uuid]
        @sessions[uuid][:active] = true
      elsif Pssh.open_sessions.keys.include?(uuid)
        user_string = Pssh.open_sessions[uuid] ? "#{Pssh.open_sessions[uuid]} (#{uuid})" : uuid
        print "\n#{user_string} attached.\n#{Pssh.prompt}"
        @sessions[uuid] = {
          data: [],
          username: Pssh.open_sessions[uuid],
          user_string: user_string,
          active: true,
          started: false
        }
        Pssh.open_sessions.delete uuid
      else
        @sessions[uuid] = {socket: self}
        self.close! and return
      end
      @sessions[uuid][:socket] = self
    end

    def on_close(env)
      uuid = params(env)['uuid']
      @sessions[uuid][:active] = false
      Thread.new do
        sleep 10
        if @sessions[uuid][:active] == false
          @sessions[uuid][:read].close
          @sessions[uuid][:write].close
          @sessions.delete uuid
          print "\n#{user_string} detached.\n#{Pssh.prompt}"
        end
      end
    end

    def close_websocket
      @sessions[@uuid][:socket].send_data({ close: true }.to_json) if @sessions[@uuid][:socket]
      @sessions[@uuid][:read].close if @sessions[@uuid][:read]
      @sessions[@uuid][:write].close if @sessions[@uuid][:write]
      @sessions[@uuid][:thread].exit if @sessions[@uuid][:thread]
      @sessions.delete @uuid
      super
    end

    def kill_all_sessions
      @sessions.each do |k,v|
        v[:socket].close!
      end
    end

    def close!
      self.close_websocket
      @killed_sessions << @uuid
    end

    # Internal: Sends a message to the tmux or screen display notifying of a
    # new user that has connected.
    #
    # Returns nothing.
    def send_display_message(uuid)
      if @existing_socket
        case Pssh.command.to_sym
        when :tmux
          `tmux -S #{@path} display-message "#{@sessions[uuid][:user_string]} has connected"`
        when :screen
          `screen -S #{@path} -X wall "#{@sessions[uuid][:user_string]} has connected"`
        end
      end
    end

    def clear_environment
      ENV['TMUX'] = nil
      ENV['STY'] = nil
    end

    def on_message(env, message)
      uuid = params(env)['uuid']
      return unless @sessions[uuid]
      case message[0]
      when 's'
        unless @sessions[uuid][:started]
          @sessions[uuid][:started] = true
          @sessions[uuid][:thread] = Thread.new do
            begin
              if @sessions[uuid]
                size = message[1..-1].split ','
                send_display_message(uuid)
                clear_environment
                @sessions[uuid][:read], @sessions[uuid][:write], @sessions[uuid][:pid] = PTY.spawn(@command)
                @sessions[uuid][:write].winsize = [size[1].to_i, size[0].to_i]

                while(@sessions[uuid] && @sessions[uuid][:active]) do
                  IO.select([@sessions[uuid][:read]])
                  begin
                    while (data = @sessions[uuid][:read].readpartial(2048)) do
                      data.encode!('UTF-16', 'UTF-8', :invalid => :replace, :replace => '')
                      data.encode!('UTF-8', 'UTF-16')
                      if data.valid_encoding?
                        @sessions[uuid][:socket].send_data({ data: data }.to_json)
                      end
                    end
                  rescue Exception => e
                    if @sessions[uuid]
                      if e.is_a?(Errno::EAGAIN)
                        retry
                      else
                        @sessions[uuid][:active] = false
                      end
                    end
                  end
                end
              end

            rescue Exception => e
              puts e.inspect
              puts e.backtrace
              puts '---'
              retry
            end
          end
        end
      when 'd'
        @sessions[uuid][:write].write_nonblock message[1..-1] if Pssh.io_mode['w']
      when 'r'
        size = message[1..-1].split ','
        @sessions[uuid][:write].winsize= [size[1].to_i, size[0].to_i]
      end
    end
  end
end
