require 'rack'
require 'thin'
require 'faye/websocket'
require 'etc'
require 'listen'
require 'pry'

class FileChange
  def initialize(change)
    parts     = change.split(":")
    @path     = parts[0]
    @hash     = parts[1]
    @contents = parts[2..-1].join('')
  end

  def create_dirs
    dirs = full_path.split('/')[1..-2]
    dirs.size.times do |i|
      dir = "/#{dirs[0..i].join('/')}"
      Dir.mkdir(dir) unless File.exists?(dir)
    end
  end

  def write
    File.open(full_path, 'w+') do |file|
      file.write @contents
    end
  end

  def full_path
    "#{Etc.getpwuid.dir}/learn/#{@path}"
  end
end

Faye::WebSocket.load_adapter('thin')

FilesystemServer = lambda do |env|
  @ws = Faye::WebSocket.new(env)

  @ws.on :open do
    @lisenter = Listen.to("#{Etc.getpwuid.dir}/learn/") do |modified, added, removed|
      if modified.any?
        @ws.send("[FS Sync Debug] Modified file(s): #{modified.join(',')}")
      end

      if added.any?
        @ws.send("[FS Sync Debug] Added file(s): #{added.join(',')}")
      end

      if removed.any?
        @ws.send("[FS Sync Debug] removed file(s): #{removed.join(',')}")
      end
    end

    @lisenter.start
  end

  @ws.on :message do |event|
    fc = FileChange.new(event.data)
    fc.create_dirs
    fc.write
  end

  @ws.rack_response
end

run FilesystemServer
