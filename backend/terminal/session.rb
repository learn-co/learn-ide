require 'pty'

module Terminal
  class Session
    attr_reader :username

    def initialize(username)
      @username = 'root'
      @stdout, @stdin, @pid = PTY.spawn("su #{username} -c '/bin/bash -il'")
    end

    def bind_to(websocket)
      # Start a new thread to loop waiting for stdout to have data to read
      Thread.new do
        loop do
          out = @stdout.readpartial(4096)
          websocket.send(out)
        end
      end
    end

    def write(data)
      @stdin << data
    end
  end
end
