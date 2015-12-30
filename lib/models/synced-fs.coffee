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
        @sendSave(project, file, buffer)

  sendSave: (project, file, buffer) ->
    @ws.send JSON.stringify({
      action: "local_save",
      project: {
        path: project.getPaths()[0]
      },
      file: {
        path: file.path
        digest: file.digest,
      },
      buffer: {
        content: window.btoa(buffer.getText())
      }
    })
