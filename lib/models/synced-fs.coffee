module.exports =
class SyncedFS
  constructor: (ws_url) ->
    @ws = new WebSocket(ws_url)

    @handleEvents()

  handleEvents: ->
    @ws.onmessage = (e) ->
      atom.notifications.addSuccess(e.data)
    @ws.onerror = ->
      atom.notifications.addError("Could not establish a connection to the Learn filesystem!")
    @ws.onclose = ->
      atom.notifications.addError("Closed connection to the Learn filesystem.")

    atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave =>
        @sendSave(editor)

  sendSave: (editor) ->
    buffer = editor.buffer
    project = editor.project
    file = buffer.file
    relDir = file.path.replace(project.getPaths()[0], '')
    rootDir = project.getPaths()[0].split('/').pop()

    @ws.send(rootDir + relDir + ":" + file.digest + ":" + buffer.getText())
