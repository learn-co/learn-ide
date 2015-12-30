class SyncedFS::Event::LocalSave
  def initialize(msg)
    @project = {
      path: msg['project']['path']
    }
    @file = {
      path: msg['file']['path'],
      digest: msg['file']['digest']
    }
    @buffer = {
      content: Base64.decode64(msg['buffer']['content'])
    }
  end

  def process
    # Check digest
    # File.open(@file)
  end

  def reply
    # Reply with ok if digest changed
    # :ok
    # else
    :noop
  end
end
