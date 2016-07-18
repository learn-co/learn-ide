ipc = require 'ipc'
fs = require 'fs-plus'
shell = require 'shell'
pathUtil = require 'path'
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
    @addTreeViewListeners()

    atom.commands.add @workspaceView,
      'learn-ide:resync': (event) => @onResync(event)

    atom.commands.onWillDispatch (event) =>
      @onTreeViewWillDispatch(event) if event.type.match(/^tree-view/)
      @onCoreConfirmWillDispatch(event) if event.type is 'core:confirm'

    atom.commands.onDidDispatch (event) =>
      console.log event.type
      switch event.type
        when 'core:confirm' then @onCoreConfirmDidDispatch(event)
        when 'core:copy', 'core:cut' then @onCoreCopyOrCut(event)
        when 'tree-view:remove' then @onTreeViewRemove(event)
        when 'tree-view:toggle' then @addTreeViewListeners(event)
        when 'tree-view:paste' then @onTreeViewPaste(event)

    atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave => @onSave(editor)

  addTreeViewListeners: ->
    el = @treeViewEl()

    if el? and not @didAddTreeViewListeners?
      @didAddTreeViewListeners = true
      el.addEventListener 'drag', (event) => @onTreeViewDrag(event)
      el.addEventListener 'drop', (event) => @onTreeViewDrop(event)
      el.addEventListener 'dragend', (event) => @onTreeViewDragEnd(event)

  onSave: (editor) =>
    {project, buffer} = editor
    {file} = buffer
    inCodeDir = !!@formatPath(file.path).match(/\.atom\/code/)
    console.log "Saving: Path - #{@formatPath file.path} Matches? - #{inCodeDir}"
    return unless inCodeDir

    @popupNoConnectionWarning() if @connectionState is 'closed'
    @sendLocalEvent @localSave(project, file, buffer)

  onCoreConfirmWillDispatch: (event) =>
    return unless @willDispatchCommand
    @newPathOnCoreConfirm = "#{@projectPath}/#{@getTreeViewDialogText()}"

  onCoreConfirmDidDispatch: (event) =>
    @syncAdditions()
    @syncMoves()
    @syncDuplication()

  onCoreCopyOrCut: (event) =>
    @treeViewCopiedPath = null

  onResync: (event) ->
    path = @getPath(event.target)
    atom.confirm
      message: 'Are you sure you want to continue?'
      detailedMessage: "The following local path will be moved to the trash and
                        replaced by its remote counterpart: \n\n#{path}"
      buttons:
        "Perform resync": =>
          shell.moveItemToTrash(path)
          @sendLocalEvent @localresync(path)
        "Cancel": null

  onTreeViewRemove: (event) =>
    @syncRemovals()

  onTreeViewPaste: (event) =>
    return unless @treeViewCopiedPath?
    source = @treeViewCopiedPath
    target = @pathAtWillDispatch
    @sendLocalEvent @localDuplicate(source, target)

  onTreeViewWillDispatch: (event) =>
    {type, target} = event

    if type is 'tree-view:copy' or type is 'tree-view:cut'
      @treeViewCopiedPath = @getPath(target) || @getTreeViewSelectedPath()
      return

    @willDispatchCommand = type
    @entriesAtWillDispatch = fs.listTreeSync(@projectPath)
    @pathAtWillDispatch = @getPath(target) || @getTreeViewSelectedPath()

  onTreeViewDragEnd: (event) =>
    @dragTargetPath = null

  onTreeViewDrag: (event) =>
    @dragTargetPath = @getPath(event.target)

  onTreeViewDrop: (event) =>
    destination = @getPath(event.target)

    return unless @dragTargetPath? and destination?
    @sendLocalEvent @localMove(@dragTargetPath, destination)

  purgeTreeViewEvent: =>
    @pathAtWillDispatch = null
    @willDispatchCommand = null
    @entriesAtWillDispatch = null
    @newPathOnCoreConfirm = null

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
    target = @newPathOnCoreConfirm

    return unless @willDispatchCommand is 'tree-view:move'
    @purgeTreeViewEvent()

    return unless source? and target? and target isnt "#{@projectPath}/"

    if pathUtil.resolve(target).startsWith(@projectPath)
      @sendLocalEvent @localMove(source, target)

  syncDuplication: =>
    source = @pathAtWillDispatch
    target = @newPathOnCoreConfirm

    return unless @willDispatchCommand is 'tree-view:duplicate'
    @purgeTreeViewEvent()

    return unless source? and target? and target isnt "#{@projectPath}/"

    if pathUtil.resolve(target).startsWith(@projectPath)
      @sendLocalEvent @localDuplicate(source, target)

  sendLocalEvent: (payload) ->
    console.log payload
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
      content: window.btoa(unescape(encodeURIComponent(@convertLineEndings(buffer.getText()))))

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

  localresync: (path) ->
    action: 'local_resync'
    project:
      path: @formatPath(@projectPath)
    file:
      path: @formatPath(path)

  formatPath: (path) ->
    if path.match(/:\\/)
      path.replace(/(.*:\\)/, '/').replace(/\\/g, '/')
    else
      path

  convertLineEndings: (text) ->
    text.replace(/\r\n|\n|\r/g, '\n')

  treeViewEl: ->
    document.getElementsByClassName('tree-view full-menu')[0]

  getTreeViewDialogText: ->
    dialog = document.querySelectorAll('.tree-view-dialog atom-text-editor.mini')[0]
    textContainer = dialog?.shadowRoot?.querySelector('.text.plain')

    return '' unless dialog? and textContainer?
    textContainer.innerText

  getTreeViewSelectedPath: ->
    selectedEntry = @treeViewEl()?.querySelector('.selected')

    return null unless selectedEntry?
    @getPath(selectedEntry)

  getPath: (el) ->
    if el.getPath?
      el.getPath()
    else if el.dataset.path?
      el.dataset.path
    else if el.firstChild?
      el.firstChild.dataset.path
    else
      undefined

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
