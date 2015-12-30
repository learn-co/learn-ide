require 'oj'
require 'base64'

module SyncedFS
  class Event
    def initialize(payload)
      @msg = Oj.load(payload)
      @event = case @msg['action']
      when 'local_open'
        LocalOpen.new(@msg)
      when 'local_save'
        LocalSave.new(@msg)
      end
    end

    def process
      @event.process
    end

    def reply
      @event.reply
    end
  end
end
