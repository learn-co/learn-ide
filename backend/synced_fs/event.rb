require 'oj'
require 'base64'

module SyncedFS
  module Event
    def self.resolve(payload)
      @msg = Oj.load(payload)
      @event = case @msg['action']
      when 'local_open'
        LocalOpen.new(@msg)
      when 'local_save'
        LocalSave.new(@msg)
      end
    end
  end
end
