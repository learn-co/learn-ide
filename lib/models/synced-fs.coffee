ipc = require 'ipc'
FileSystemTree = require './file-system-tree'
_ = require 'underscore-plus'

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

    @workspaceView = atom.views.getView(atom.workspace)
    @projectPath = atom.project.getPaths()[0]
    @filesystemTree = new FileSystemTree(@projectPath)
    @handleEvents()

  expandTreeView: ->
    atom.commands.dispatch(@workspaceView, 'tree-view:reveal-active-file')

  handleEvents: ->
    atom.commands.onDidDispatch (event) =>
      console.log event.type
      switch event.type
        when 'core:confirm' then @onCoreConfirm(event)
        when 'tree-view:remove' then @onTreeViewRemove(event)

    atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave =>
        @onSave()
      editor.onDidChangePath ->
        console.log 'PATH CHANGED'

    atom.workspace.onDidOpen ({uri, item, pane, index}) ->
      console.log 'OPENED ' + uri

  onSave: (editor) =>
    editorElement = atom.views.getView(editor)
    atom.commands.dispatch(editorElement, 'line-ending-selector:convert-to-LF')

    {project, buffer} = editor
    {file} = buffer
    inCodeDir = !!@formatPath(file.path).match(/\.atom\/code/)
    console.log "Saving: Path - #{@formatPath file.path} Matches? - #{inCodeDir}"
    return unless inCodeDir

    @popupNoConnectionWarning() if @connectionState is 'closed'
    @sendSave(editor.project, file, buffer)

  onCoreConfirm: ->
    @syncAdditions()

  syncAdditions: ->
    prevEntries = _.clone(@filesystemTree.entries)
    newEntries = _.difference(@filesystemTree.reload(), prevEntries)
    return if _.isEmpty(newEntries)

    deepestPath = _.max(newEntries, (entry) -> entry.length)
    @sendAddFile(deepestPath) if @filesystemTree.isFile(deepestPath)
    @sendAddFolder(deepestPath) if @filesystemTree.isDirectory(deepestPath)

  onTreeViewRemove: (node) ->
    @syncRemovals()

  syncRemovals: ->
    prevEntries = _.clone(@filesystemTree.entries)
    removedEntries = _.difference(prevEntries, @filesystemTree.reload())
    return if _.isEmpty(removedEntries)

    shallowPath = _.min(removedEntries, (entry) -> entry.length)
    @sendRemove(shallowPath)

  sendAddFile: (path) ->
    ipc.send 'fs-local-add-file', JSON.stringify(
      action: 'local_add_file'
      project:
        path: @formatPath(@projectPath)
      file:
        path: @formatPath(path)
      )

  sendAddFolder: (path) ->
    ipc.send 'fs-local-add-folder', JSON.stringify(
      action: 'local_add_folder'
      project:
        path: @formatPath(@projectPath)
      file:
        path: @formatPath(path)
      )

  sendSave: (project, file, buffer) ->
    ipc.send 'fs-local-save', JSON.stringify(
      action: 'local_save'
      project:
        path: @formatPath(project.getPaths()[0])
      file:
        path: @formatPath(file.path)
        digest: file.digest,
      buffer:
        content: window.btoa(unescape(encodeURIComponent(buffer.getText())))
      )

  sendRemove: (path) ->
    ipc.send 'fs-local-delete', JSON.stringify(
      action: 'local_delete'
      project:
        path: @formatPath(@projectPath)
      file:
        path: @formatPath(path)
      )

  formatPath: (path) ->
    if path.match(/:\\/)
      path.replace(/(.*:\\)/, '/').replace(/\\/g, '/')
    else
      path

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
