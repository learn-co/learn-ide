ipc = require 'ipc'

module.exports =
class SyncedFS
  constructor: (ws_url) ->
    ipc.send 'register-new-fs-connection', ws_url
    ipc.on 'remote-open-event', (file) ->
      atom.workspace.open(file)

    @handleEvents()
    @treeViewEventQueue = []

  handleEvents: ->
    atom.workspace.observeTextEditors (editor) =>
      project = editor.project
      buffer = editor.buffer
      file = buffer.file

      editor.onDidSave =>
        if this.formatFilePath(file.path).match(/\.atom\/code/)
          @sendSave(project, file, buffer)
      editor.onDidChangePath =>
        console.log('PATH CHANGED')

    atom.commands.onDidDispatch (e) =>
      if e.type == 'tree-view:remove'
        if e.target.attributes['data-path']
          path = e.target.attributes['data-path'].nodeValue
        else
          path = e.target.file.path

        ipc.send 'fs-local-delete', JSON.stringify({
          action: 'local_delete',
          project: {
            path: this.formatFilePath(atom.project.getPaths()[0])
          },
          file: {
            path: this.formatFilePath(path)
          }
        })
      else if e.type == 'tree-view:add-file'
        console.log(e)
        # Add event to queue
      else if e.type == 'tree-view:move'
        window.currentEvent = e
        @treeViewEventQueue.push
          type: 'move'
          event: e
      else if e.type == 'core:cancel'
        @treeViewEventQueue = []
      else if e.type == 'core:confirm'
        # do whatever's necessary to confirm event in queue

        window.confirmedEvent = e
        confirmedEvent = @treeViewEventQueue.shift()

        switch confirmedEvent.type
          when 'move'
            event = confirmedEvent.event
            from = event.target.getAttribute('data-name')
            fromPath = event.target.getAttribute('data-path')
          when 'addFile'
            true
        console.log(e)
      else
        console.log(e.type)

  sendSave: (project, file, buffer) ->
    ipc.send 'fs-local-save', JSON.stringify({
      action: 'local_save',
      project: {
        path: this.formatFilePath(project.getPaths()[0])
      },
      file: {
        path: this.formatFilePath(file.path)
        digest: file.digest,
      },
      buffer: {
        content: window.btoa(buffer.getText())
      }
    })

  formatFilePath: (path) ->
    if path.match(/:\\/)
      return path.replace(/(.*:\\)/, '/').replace(/\\/g, '/')
    else
      return path
