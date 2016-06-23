ipc = require 'ipc'

module.exports =
class SyncedFS
  constructor: (ws_url, isTermView=false) ->
    ipc.send 'register-new-fs-connection', ws_url
    ipc.on 'remote-open-event', (file) =>
      if !isTermView
        atom.workspace.open(file)
          .then (editor) =>
            @expandTreeView()

            setTimeout =>
              pane = (atom.workspace.getPanes().filter (p) =>
                return p.activeItem == editor
              )[0]

              pane.activate() if pane
            , 0

    ipc.on 'connection-state', (state) =>
      @connectionState = state

    @handleEvents()
    @treeViewEventQueue = []

  expandTreeView: ->
    workspaceView = atom.views.getView(atom.workspace)
    atom.commands.dispatch(workspaceView, 'tree-view:reveal-active-file')

  handleEvents: ->
    atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave => @onSave()
      editor.onDidChangePath -> console.log 'PATH CHANGED'

    atom.commands.onDidDispatch ({type}) =>
      console.log type
      @onCancel() if type is 'core:cancel'
      @onConfirm(e) if type is 'core:confirm'

    atom.commands.add atom.views.getView(atom.workspace),
      'tree-view:remove': ({target}) => @onRemove(target)
      'tree-view:add-file': (e) => @queueTreeViewEvent(e)
      'tree-view:move': (e) => @queueTreeViewEvent(e)

  sendSave: (project, file, buffer) ->
    ipc.send 'fs-local-save', JSON.stringify(
      action: 'local_save'
      project:
        path: this.formatFilePath(project.getPaths()[0])
      file:
        path: this.formatFilePath(file.path)
        digest: file.digest,
      buffer:
        content: window.btoa(unescape(encodeURIComponent(buffer.getText())))
      )

  formatFilePath: (path) ->
    return path.replace(/(.*:\\)/, '/').replace(/\\/g, '/') if path.match(/:\\/)
    path

  onRemove: (target) ->
    if target.attributes['data-path']
      path = target.attributes['data-path'].nodeValue
    else
      path = target.file.path

    ipc.send 'fs-local-delete', JSON.stringify(
      action: 'local_delete'
      project:
        path: this.formatFilePath atom.project.getPaths()[0]
      file:
        path: this.formatFilePath path
      )

  onConfirm: (e) =>
    confirmedEvent = @treeViewEventQueue.shift()
    return unless confirmedEvent?

    {event, type} = confirmedEvent
    if type is 'tree-view:move'
      from = event.target.getAttribute('data-name')
      fromPath = event.target.getAttribute('data-path')
    if type is 'tree-view:add-file'
      window.confirmedEvent = event
      true

  onCancel: =>
    @treeViewEventQueue = []

  onSave: (editor) =>
    editorElement = atom.views.getView(editor)
    atom.commands.dispatch(editorElement, 'line-ending-selector:convert-to-LF')

    {project, buffer} = editor
    {file} = buffer
    inCodeDir = !!@formatFilePath(buffer.file.path).match(/\.atom\/code/)
    console.log 'Saving: Path - ' + @formatFilePath buffer.file.path + ' Matches? - ' + inCodeDir
    return unless inCodeDir

    @popupNoConnectionWarning() if @connectionState is 'closed'
    @sendSave(editor.project, buffer.file, buffer)

  queueTreeViewEvent: (event) =>
    @treeViewEventQueue.push(type: event.type, event: event)

  popupNoConnectionWarning: ->
    noConnectionPopup = document.createElement 'div'
    noConnectionPopup.setAttribute 'style', 'width: 100%; text-align: center;'
    noConnectionTextContainer = document.createElement 'div'
    noConnectionTextContainer.setAttribute 'style', 'margin-bottom: 14px; margin-top: 20px; font-weight: bold; font-size: 14px; color: red;'
    noConnectionTextContainer.appendChild document.createTextNode "You aren't currently connected to Learn, and local changes won't sync. Please save this file again when you reconnect."
    noConnectionButtonContainer = document.createElement 'div'
    noConnectionButton = document.createElement 'input'
    noConnectionButton.setAttribute 'type', 'submit'
    noConnectionButton.setAttribute 'value', 'OK'
    noConnectionButton.setAttribute 'style', 'width: 10%; color: black; margin-bottom: 7px;'
    noConnectionButtonContainer.setAttribute 'style', 'width: 100%, text-align: center;'
    noConnectionButtonContainer.appendChild noConnectionButton

    noConnectionPopup.appendChild noConnectionTextContainer
    noConnectionPopup.appendChild noConnectionButtonContainer
    panel = atom.workspace.addModalPanel item: noConnectionPopup

    noConnectionButton.addEventListener 'click', (e) =>
      panel.destroy()
