require 'oj'
require 'base64'

module SyncedFS
  module Event
    class LocalSave
      def initialize(msg)
        @project = {
          path: msg['project']['path']
        }
        @file    = {
          path: msg['file']['path'],
          digest: msg['file']['digest']
        }
        @buffer  = {
          content: Base64.decode64(msg['buffer']['content'])
        }
      end
    end

    def self.resolve(payload)
      msg = Oj.load(payload)

      case msg['action']
      when 'local_save'
        LocalSave.new(msg)
      end
    end
  end
end
