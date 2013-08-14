module Pssh
  class WebConsole
    def render(view, opts = {})
      [200, { 'Content-Type' => 'text/html' }, Tilt::HamlTemplate.new("../views/#{view}.haml").render(self, opts)]
    end

    def call(env)
      if env['HTTP_AUTHORIZATION']
        auth = env['HTTP_AUTHORIZATION'].split(' ')[1]
        username = Base64.decode64(auth).split(':')[0]
      else
        username = nil
      end
      render 'index', unique_id: Pssh.create_session(username)
    end
  end
end
