class SyncedFS::Event::LocalOpen
  def initialize(msg)
    @project = {
      path: msg['project']['path']
    }
    @file = {
      path: msg['file']['path'],
      digest: msg['file']['digest']
    }
  end

  def process
    # Check digest
    # File.open(@file)
  end

  def reply
    # Reply with new file if digest changed
    # ...
    # else
    :noop
  end
end
