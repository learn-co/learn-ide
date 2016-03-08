{$, View} = require 'atom-space-pen-views'
file_sys  = require 'fs'
mkdirp    = require 'mkdirp'
exec      = require('child_process').execSync

module.exports =
class TerminalView extends View
  @content: ->
    @div class: 'learn-synced-fs-status inline-block icon-terminal'

  constructor: (state, fs) ->
    super

    @fs = fs
    @ws = fs.ws

    # Default text
    @text(" Learn")
    @element.style.color = '#d92626'

    @handleEvents()

  deleteDirectoryRecursive: (path) ->
    self = this
    files = []
    sep = if /^win/.test(process.platform) then '\\' else '/'
    console.log("SEP: " + sep)

    if file_sys.existsSync(path)
      files = file_sys.readdirSync(path)
      files.forEach (file, index) ->
        curPath = path + sep + file

        if sep == '\\'
          isdir = exec('if exist ' + curPath + '\* echo true').match(/true/)
        else
          isdir = file_sys.lstatSync(curPath).isDirectory()

        if isdir
          self.deleteDirectoryRecursive(curPath)
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
        switch event.event
          when 'remote_create'
            console.log('Created: ' + event.location + '/' + event.file)
            if event.directory
              mkdirp.sync(atom.getUserWorkingDirPath() + '/' + event.location + '/' + event.file)
            else
              mkdirp.sync(atom.getUserWorkingDirPath() + '/' + event.location)
              file_sys.openSync(atom.getUserWorkingDirPath() + '/' + event.location + '/' + event.file, 'a')

              @ws.send JSON.stringify({
                action: 'request_content',
                location: event.location,
                file: event.file
              })
          when 'content_response'
            content = new Buffer(event.content, 'base64').toString()
            file_sys.writeFileSync atom.getUserWorkingDirPath() + '/' + event.location + '/' + event.file, content
          when 'remote_delete'
            if event.directory
              this.deleteDirectoryRecursive atom.getUserWorkingDirPath() + '/' + event.location + '/' + event.file
            else
              delPath = atom.getUserWorkingDirPath() + '/' + event.location + '/' + event.file
              if file_sys.existsSync(delPath)
                file_sys.unlinkSync(delPath)
          when 'remote_move_from'
            console.log('move_from')
          when 'remote_move_to'
            console.log('move_to')
          when 'remote_modify'
            if !event.directory
              mkdirp.sync(atom.getUserWorkingDirPath() + '/' + event.location)
              file_sys.openSync(atom.getUserWorkingDirPath() + '/' + event.location + '/' + event.file, 'a')

              @ws.send JSON.stringify({
                action: 'request_content',
                location: event.location,
                file: event.file
              })
          when 'remote_open'
            console.log('Opened: ' + event.location + '/' + event.file)

            if event.location == ''
              atom.workspace.open(event.file)
            else
              atom.workspace.open(event.location + '/' + event.file)

      catch err
        console.log(err)
      console.log("SyncedFS debug: " + e)
    @ws.onclose = =>
      @element.style.color = '#d92626'
