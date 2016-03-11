module.exports =
class SyncedFS
  constructor: (ws_url) ->
    @ws = new WebSocket(ws_url)

    @handleEvents()

  handleEvents: ->
    # TODO: See if we can watch the entire project dir using Atom's Directory API
    atom.workspace.observeTextEditors (editor) =>
      project = editor.project
      buffer = editor.buffer
      file = buffer.file

      editor.onDidSave =>
        if this.formatFilePath(file.path).match(/\.atom\/code/)
          @sendSave(project, file, buffer)

    atom.commands.onDidDispatch (e) =>
      if e.type == 'tree-view:remove'
        if e.target.attributes['data-path']
          path = e.target.attributes['data-path'].nodeValue
        else
          path = e.target.file.path

        @ws.send JSON.stringify({
          action: "local_delete",
          project: {
            path: this.formatFilePath(atom.project.getPaths()[0])
          },
          file: {
            path: this.formatFilePath(path)
          }
        })
      else if e.type == 'tree-view:add-file' || e.type == 'tree-view:add-folder' || e.type == 'core:confirm'
        true
        # No good way yet to handle creations until a file is written

  sendSave: (project, file, buffer) ->
    @ws.send JSON.stringify({
      action: "local_save",
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
