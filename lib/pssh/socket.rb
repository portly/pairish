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
        Pssh.pty.send_display_message user_string
        @sessions[uuid] = {
          data: [],
          username: Pssh.open_sessions[uuid],
          user_string: user_string,
          active: true,
          started: false,
          winsize: []
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
          @sessions.delete uuid
          print "\n#{user_string} detached.\n#{Pssh.prompt}"
        end
      end
    end

    # Public: Writes the same data to all the open sessions.
    #
    # Returns nothing.
    def write(data)
      @sessions.each do |k,v|
        v[:socket].send_data({ data: data }.to_json)
      end
    end

    def close_websocket
      self.send_data({ close: true }.to_json)
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

    def on_message(env, message)
      uuid = params(env)['uuid']
      return unless @sessions[uuid]
      case message[0]
      when 's'
        @sessions[uuid][:started] = true
        size = message[1..-1].split ','
        @sessions[uuid][:winsize] = [size[0].to_i, size[1].to_i]
        send_data({ data: Pssh.pty.stream }.to_json)
        Pssh.pty.resize!
      when 'd'
        Pssh.pty.write message[1..-1]
      when 'r'
        size = message[1..-1].split ','
        @sessions[uuid][:winsize] = [size[0].to_i, size[1].to_i]
        Pssh.pty.resize!
      end
    end
  end
end
