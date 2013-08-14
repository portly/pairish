module Pssh
  class Console

    COMMANDS = %w(list block unblock sessions kill-session exit).sort
    BANNER = <<-BANNER
      ------------------------------------------------------------------
      help\t\tDisplays this help menu.
      info\t\tDisplays current tmux settings and configuration.
      list[ sessions]\tShow the currently open sessions.
      kill-session[s]\tKill either all sessions or a specific by id.
        --all\t\tKills all the open sessions.
        'session id'\tKills only the session specified by the id.
      exit\t\tCloses all active sessions and exits.
      ------------------------------------------------------------------
      Tip: Use tab-completion for commands and session ids.
    BANNER

    def initialize(opts = {})

      @pty = opts[:pty]
      @web = opts[:web]

      begin
        puts "[ pssh terminal ]"
        puts "Service started on port #{Pssh.port}."
        puts "Type 'help' for more information."

        Readline.completion_append_character = " "
        Readline.completion_proc = completion_proc

        while command = Readline.readline(Pssh.prompt, true)
          command.strip!
          command.gsub!(/\s+/, ' ')
          case command
          when 'help'
            puts BANNER.gsub(/^ {6}/,'')
          when 'exit'
            @pty.kill_all_sessions
            Kernel.exit!
          when 'info'
            puts 'Current Configuration:'
            if @pty.path
              puts "Socket: #{@pty.path}"
              puts "(Attach to this socket with `#{@pty.attach_cmd}`)"
            else
              puts 'Connections are made to a vanilla shell.'
            end
          when 'list sessions', 'list'
            @pty.sessions.each do |k,v|
              puts v[:user_string]
            end
          when /^kill-sessions?\s?(.*)$/
            if $1 == '--all'
              puts 'disconnecting all clients'
              @pty.kill_all_sessions
            else
              puts "disconnecting #{$1}"
              if @pty.sessions.keys.include?($1)
                @pty.sessions[$1][:socket].close!
              else
                @pty.sessions.each do |k, sess|
                  if sess[:username] == $1
                    sess[:socket].close!
                  end
                end
              end
            end
          end
        end
      rescue Exception => e
        puts e.inspect
        puts e.backtrace
        retry
      end
    end

    def completion_proc
      @completion_proc ||= proc { |s| (COMMANDS + Pssh.open_sessions.keys + Pssh.open_sessions.values.uniq).grep( /^#{Regexp.escape(s)}/ ) }
    end
  end
end
