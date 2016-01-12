require 'pty'

module Terminal
  class Session
    def initialize
      @stdout, @stdin, @pid = PTY.spawn("/bin/bash -li")
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
