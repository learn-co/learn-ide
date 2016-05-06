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
      project = editor.project
      buffer = editor.buffer
      file = buffer.file

      editor.onDidSave =>
        console.log 'Saving: Path - ' + this.formatFilePath(buffer.file.path) + ' Matches? - ' + !!this.formatFilePath(buffer.file.path).match(/\.atom\/code/)
        if this.formatFilePath(buffer.file.path).match(/\.atom\/code/)
          if @connectionState == 'closed'
            @popupNoConnectionWarning()

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
        if confirmedEvent
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
        content: window.btoa(unescape(encodeURIComponent(buffer.getText())))
      }
    })

  #formattedText: (text) ->
    #try
      #window.btoa(text)
    #catch
      #window.btoa(unescape(encodeURIComponent(text)))

  formatFilePath: (path) ->
    if path.match(/:\\/)
      return path.replace(/(.*:\\)/, '/').replace(/\\/g, '/')
    else
      return path
