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
        if this.formatFilePath(buffer.file.path).match(/\.atom\/code/)
          @sendSave(editor.project, buffer.file, buffer)
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
      else if e.type == 'tree-view:add-file' || e.type == 'tree-view:move'
        @treeViewEventQueue.push
          type: e.type
          event: e
      else if e.type == 'core:cancel'
        @treeViewEventQueue = []
      else if e.type == 'core:confirm'
        confirmedEvent = @treeViewEventQueue.shift()
        event = confirmedEvent.event

        switch confirmedEvent.type
          when 'tree-view:move'
            from = event.target.getAttribute('data-name')
            fromPath = event.target.getAttribute('data-path')
          when 'tree-view:add-file'
            window.confirmedEvent = event
            true
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
