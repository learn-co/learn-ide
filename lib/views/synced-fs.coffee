{$, View} = require 'atom-space-pen-views'
file_sys  = require 'fs'
mkdirp    = require 'mkdirp'
exec      = require('child_process').execSync
spawn     = require('child_process').spawnSync
crossSpawn = require('cross-spawn').spawn
rmdir     = require('rimraf')

module.exports =
class TerminalView extends View
  @content: ->
    @div class: 'learn-synced-fs-status inline-block icon-terminal'

  constructor: (state, fs) ->
    super

    @fs = fs
    @ws = fs.ws
    @sep = if /^win/.test(process.platform) then '\\' else '/'
    @windows = if @sep == '\\' then true else false

    # Default text
    @text(" Learn")
    @element.style.color = '#d92626'

    @handleEvents()

  formatFilePath: (path) ->
    if path.match(/:\\/)
      return path.replace(/(.*:\\)/, '/').replace(/\\/g, '/')
    else
      return path

  deleteDirectoryRecursive: (path) ->
    console.log("PATH: " + path)
    self = this
    files = []

    if file_sys.existsSync(path)
      #if sep == '\\'
      #  files = file_sys.readdirSync(path)
      #  files.forEach (file, index) ->
      #    curPath = path + sep + file
      #  #res = crossSpawn.sync('rd', ['/S', '/Q', path])
      #  res = crossSpawn.sync('dir', [path])
      #  console.log(res.stdout.toString())
      #  if res.stdout.toString().match(/<DIR>/)
      #    self.deleteDirectoryRecursive(curPath)
      #else
      files = file_sys.readdirSync(path)
      files.forEach (file, index) ->
        curPath = path + @sep + file

        if sep == '\\'
          console.log('checking if dir. curPath: ' + curPath)
          #isdir = exec('if exist ' + curPath + '\* echo true').match(/true/)
          isdir = crossSpawn.sync('dir', [curPath]).stdout.toString().match(/<DIR>/)
          console.log('CUR PATH: ' + curPath)
          console.log('IS DIR: ' + isdir)
        else
          isdir = file_sys.lstatSync(curPath).isDirectory()

        if isdir
          self.deleteDirectoryRecursive(curPath)
          #out = crossSpawn.sync('takeown', ['/f', curPath, '/r', '/d', 'y'])
        else
          if @windows
            console.log('DELETING FILE: ' + curPath)
            #out2 = crossSpawn.sync('takeown', ['/F', curPath])
            #console.log('CURPATH: ' + curPath)
            #out = crossSpawn.sync('del', [curPath, '/q', '/f'])
            #console.log('DELETE ATTEMPT: ' + out.stdout.toString())
            #console.log('DELETE ATTEMPT FAILED: ' + out.stderr.toString())
            file_sys.unlinkSync(curPath)
          else
            file_sys.unlinkSync(curPath)

      file_sys.rmdirSync(path)

  handleEvents: ->
    @ws.onopen = (e) =>
      @element.style.color = '#73c990'
    @ws.onmessage = (e) =>
      try
        console.log(e.data)
        event = JSON.parse(e.data)
        if !(event.location.match(/node_modules/) || event.file.match(/node_modules/))
          switch event.event
            when 'remote_create'
              console.log('Created: ' + this.formatFilePath(event.location) + @sep + event.file)
              if event.directory
                if @windows
                  exec('mkdir ' + atom.getUserWorkingDirPath() + @sep + this.formatFilePath(event.location) + @sep + event.file)
                else
                  mkdirp.sync(atom.getUserWorkingDirPath() + @sep + event.location + @sep + event.file)
              else
                #if @windows
                #  exec('mkdir ' + atom.getUserWorkingDirPath() + @sep + this.formatFilePath(event.location))
                #else
                mkdirp.sync(atom.getUserWorkingDirPath() + @sep + event.location)

                file_sys.openSync(atom.getUserWorkingDirPath() + @sep + this.formatFilePath(event.location) + @sep + event.file, 'a')

                @ws.send JSON.stringify({
                  action: 'request_content',
                  location: event.location,
                  file: event.file
                })
            when 'content_response'
              content = new Buffer(event.content, 'base64').toString()
              file_sys.writeFileSync atom.getUserWorkingDirPath() + @sep + this.formatFilePath(event.location) + @sep + event.file, content
            when 'remote_delete'
              if event.directory
                if @windows
                  rmdir atom.getUserWorkingDirPath() + @sep + this.formatFilePath(event.location) + @sep + event.file, (error) ->
                    console.log('RMDIR ERROR: ' + error)
                else
                  if event.location.length
                    this.deleteDirectoryRecursive atom.getUserWorkingDirPath() + @sep + event.location + @sep + event.file
                  else
                    this.deleteDirectoryRecursive atom.getUserWorkingDirPath() + @sep + event.file
              else
                delPath = atom.getUserWorkingDirPath() + @sep + this.formatFilePath(event.location) + @sep + event.file

                if file_sys.existsSync(delPath)
                  file_sys.unlinkSync(delPath)
            when 'remote_move_from'
              console.log('move_from')
            when 'remote_move_to'
              console.log('move_to')
            when 'remote_modify'
              if !event.directory
                if @windows
                  exec('mkdir ' + atom.getUserWorkingDirPath() + @sep + this.formatFilePath(event.location))
                else
                  mkdirp.sync(atom.getUserWorkingDirPath() + @sep + event.location)

                file_sys.openSync(atom.getUserWorkingDirPath() + @sep + this.formatFilePath(event.location) + @sep + event.file, 'a')

                @ws.send JSON.stringify({
                  action: 'request_content',
                  location: event.location,
                  file: event.file
                })
            when 'remote_open'
              console.log('Opened: ' + this.formatFilePath(event.location) + @sep + event.file)

              if event.location.length
                atom.workspace.open(this.formatFilePath(event.location) + @sep + event.file)
              else
                atom.workspace.open(event.file)

      catch err
        console.log(err)
      console.log("SyncedFS debug: " + e)
    @ws.onclose = =>
      @element.style.color = '#d92626'
