ipc = require 'ipc'
fs = require 'fs-plus'
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
    @handleEvents()

  expandTreeView: ->
    atom.commands.dispatch(@workspaceView, 'tree-view:reveal-active-file')

  handleEvents: ->
    atom.commands.onWillDispatch (event) =>
      @onTreeViewWillDispatch(event) if event.type.match(/^tree-view/)

    atom.commands.onDidDispatch (event) =>
      console.log event.type
      switch event.type
        when 'core:confirm' then @onCoreConfirm(event)
        when 'tree-view:remove' then @onTreeViewRemove(event)

    atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave => @onSave(editor)

  onSave: (editor) =>
    @convertLineEndings(editor)

    {project, buffer} = editor
    {file} = buffer
    inCodeDir = !!@formatPath(file.path).match(/\.atom\/code/)
    console.log "Saving: Path - #{@formatPath file.path} Matches? - #{inCodeDir}"
    return unless inCodeDir

    @popupNoConnectionWarning() if @connectionState is 'closed'
    @sendLocalEvent @localSave(editor.project, file, buffer)

  onCoreConfirm: (event) ->
    setTimeout =>
      @syncAdditions()
      @syncMoves()
      @syncDuplication()
    , 10

  onTreeViewRemove: (event) =>
    @syncRemovals()

  onTreeViewWillDispatch: (event) =>
    {type, target} = event
    @pathAtWillDispatch = target.dataset.path || target.firstChild.dataset.path
    @willDispatchCommand = type
    @entriesAtWillDispatch = fs.listTreeSync(@projectPath)

  purgeTreeViewEvent: =>
    @pathAtWillDispatch = null
    @willDispatchCommand = null
    @entriesAtWillDispatch = null

  syncRemovals: =>
    prevEntries = @entriesAtWillDispatch

    return unless @willDispatchCommand is 'tree-view:remove'
    @purgeTreeViewEvent()

    removedEntries = _.difference(prevEntries, fs.listTreeSync(@projectPath))
    return unless removedEntries.length

    sorted = _.sortBy(removedEntries, 'length').reverse()
    _.each(sorted, (entry) => @sendLocalEvent @localRemove(entry))

  syncAdditions: =>
    prevEntries = @entriesAtWillDispatch

    return unless @willDispatchCommand?.match(/tree-view:add/)
    @purgeTreeViewEvent()

    return unless prevEntries?

    newEntries = _.difference(fs.listTreeSync(@projectPath), prevEntries)
    return unless newEntries.length

    deepestPath = _.max(newEntries, (entry) -> entry.length)
    @sendLocalEvent @localAddFile(deepestPath) if fs.isFileSync(deepestPath)
    @sendLocalEvent @localAddFolder(deepestPath) if fs.isDirectorySync(deepestPath)

  syncMoves: =>
    source = @pathAtWillDispatch
    prevEntries = @entriesAtWillDispatch

    return unless @willDispatchCommand is 'tree-view:move'
    @purgeTreeViewEvent()

    return unless prevEntries?

    unless source?
      oldEntries = _.difference(prevEntries, fs.listTreeSync(@projectPath))
      source = _.min(oldEntries, (entry) -> entry.length)

    newEntries = _.difference(fs.listTreeSync(@projectPath), prevEntries)
    return unless newEntries.length

    target = _.max(newEntries, (entry) -> entry.length)
    @sendLocalEvent @localMove(source, target)

  syncDuplication: =>
    source = @pathAtWillDispatch
    prevEntries = @entriesAtWillDispatch

    return unless @willDispatchCommand is 'tree-view:duplicate'
    @purgeTreeViewEvent()

    return unless source? and prevEntries?

    newEntries = _.difference(fs.listTreeSync(@projectPath), prevEntries)
    return unless newEntries.length

    target = _.max(newEntries, (entry) -> entry.length)
    @sendLocalEvent @localDuplicate(source, target)

  sendLocalEvent: (payload) ->
    ipc.send 'fs-local-event', JSON.stringify(payload)

  localAddFile: (path) ->
    action: 'local_add_file'
    project:
      path: @formatPath(@projectPath)
    file:
      path: @formatPath(path)

  localAddFolder: (path) ->
    action: 'local_add_folder'
    project:
      path: @formatPath(@projectPath)
    file:
      path: @formatPath(path)

  localSave: (project, file, buffer) ->
    action: 'local_save'
    project:
      path: @formatPath(project.getPaths()[0])
    file:
      path: @formatPath(file.path)
      digest: file.digest,
    buffer:
      content: window.btoa(unescape(encodeURIComponent(buffer.getText())))

  localRemove: (path) ->
    action: 'local_delete'
    project:
      path: @formatPath(@projectPath)
    file:
      path: @formatPath(path)

  localMove: (source, target) ->
    action: 'local_move'
    project:
      path: @formatPath(@projectPath)
    file:
      path: @formatPath(target)
    from: @formatPath(source)

  localDuplicate: (source, target) ->
    action: 'local_duplicate'
    project:
      path: @formatPath(@projectPath)
    file:
      path: @formatPath(target)
    from: @formatPath(source)

  formatPath: (path) ->
    if path.match(/:\\/)
      path.replace(/(.*:\\)/, '/').replace(/\\/g, '/')
    else
      path

  convertLineEndings: (editor) ->
    editorElement = atom.views.getView(editor)
    atom.commands.dispatch(editorElement, 'line-ending-selector:convert-to-LF')

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
