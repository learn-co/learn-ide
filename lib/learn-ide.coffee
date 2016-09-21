_ = require 'underscore-plus'
path = require 'path'
ipc = require 'ipc'
localStorage = require './local-storage'
{CompositeDisposable} = require 'atom'
Terminal = require './models/terminal'
SyncedFS = require './models/synced-fs'
TerminalView = require './views/terminal'
SyncedFSView = require './views/synced-fs'
{EventEmitter} = require 'events'
LearnUpdater = require './models/learn-updater'
LocalhostProxy = require './models/localhost-proxy'
WebWindow = require './models/web-window'
bus = require('./event-bus')()

require('dotenv').config({
  path: path.join(__dirname, '../.env'),
  silent: true
});

WS_SERVER_URL = (->
  config = _.defaults
    host: process.env['IDE_WS_HOST'],
    port: process.env['IDE_WS_PORT']
  ,
    host: 'ile.learn.co',
    port: 443,
    protocol: 'wss'

  if config.port != 443
    config.protocol = 'ws'

  return config.protocol + '://' + config.host + ':' + config.port;
)()

module.exports =
  activate: (state) ->
    require('./init.coffee')
    @activateEventHandlers()
    @activateIDE(state)

  activateEventHandlers: ->
    # keep track of the focused window's pid
    setLastFocusedWindow = ->
      localStorage.set('lastFocusedWindow', process.pid)
    setLastFocusedWindow()
    window.onfocus = setLastFocusedWindow

    # listen for learn:open event from other render processes (url handler):w
    bus.on 'learn:open', (lab) =>
      console.log('opening lab from bus')
      console.log(lab)
      @termView.openLab(lab.slug)

    # tidy up when the window closes
    atom.getCurrentWindow().on 'close', =>
      @cleanup()

  activateIDE: (state) ->
    @oauthToken = atom.config.get('learn-ide.oauthToken')
    @vmPort = atom.config.get('learn-ide.vmPort')
    @progressBarPopup = null
      

    isTerminalWindow = atom.isTerminalWindow

    @term = new Terminal("#{WS_SERVER_URL}/go_terminal_server?token=#{@oauthToken}")
    @termView = new TerminalView(@term, null, isTerminalWindow)

    if isTerminalWindow
      document.getElementsByClassName('terminal-view-resize-handle')[0].setAttribute('style', 'display:none;')
      document.getElementsByClassName('inset-panel')[0].setAttribute('style', 'display:none;')
      document.getElementsByClassName('learn-terminal')[0].style.height = '448px'
      workspaceView = atom.views.getView(atom.workspace)
      atom.commands.dispatch(workspaceView, 'tree-view:toggle')

    @fs = new SyncedFS("#{WS_SERVER_URL}/fs_server?token=#{@oauthToken}", isTerminalWindow)
    @fsViewEmitter = new EventEmitter
    @fsView = new SyncedFSView(state, @fs, @fsViewEmitter, isTerminalWindow)

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'learn-ide:open': (e) => @termView.openLab(e.detail.path)
      'learn-ide:toggle-terminal': () => @termView.toggle()
      'learn-ide:toggle-focus': => @termView.toggleFocus()
      'learn-ide:reset': =>
        @term.term.write('\n\rReconnecting...\r')
        ipc.send 'reset-connection'
        ipc.send 'connection-state-request'
      'application:update-ile': -> (new LearnUpdater).checkForUpdate()

    @termView.toggle()

    openPath = localStorage.get('learnOpenLabOnActivation')
    if openPath
      localStorage.delete('learnOpenLabOnActivation')
      @termView.openLab(openPath)

    @passingIcon = 'http://i.imgbox.com/pAjW8tY1.png'
    @failingIcon = 'http://i.imgbox.com/vVZZG1Gx.png'

    @startLocalhostProxy()

    ipc.send 'register-for-notifications', @oauthToken

    ipc.on 'remote-log', (msg) ->
      console.log(msg)

    ipc.on 'learn-submit-alert', (event) ->
      new WebWindow(event.file, resizable: false)

    ipc.on 'new-notification', (data) =>
      icon = if data.passing == 'true' then @passingIcon else @failingIcon

      notif = new Notification data.displayTitle,
        body: data.message
        icon: icon

      notif.onclick = ->
        notif.close()

    ipc.on 'in-app-notification', (notifData) =>
      atom.notifications['add' + notifData.type.charAt(0).toUpperCase() + notifData.type.slice(1)] notifData.message, {detail: notifData.detail, dismissable: notifData.dismissable}

    ipc.on 'progress-bar-update', (value) =>
      atom.getCurrentWindow().setProgressBar(value)

      if !@progressBarPopup
        progressBarContainer = document.createElement 'div'
        progressBarInnerDiv = document.createElement 'div'
        progressBarInnerDiv.className = 'w3-progress-container w3-round-xlarge w3-dark-grey'
        progressBar = document.createElement 'div'
        progressBar.className = 'learn-progress-bar w3-progressbar w3-round-xlarge w3-green'
        progressBarInnerDiv.appendChild progressBar
        progressBarContainer.appendChild progressBarInnerDiv

        @progressBarPopup = atom.workspace.addModalPanel item: progressBarContainer

      if value >= 0 && value < 1
        @progressBarPopup.item.getElementsByClassName('learn-progress-bar')[0].setAttribute 'style', 'width:' + value * 100 + '%;'
      else
        @progressBarPopup.destroy()
        @progressBarPopup = null

    @fsViewEmitter.on 'toggleTerminal', (focus) =>
      @termView.toggle(focus)

    autoUpdater = new LearnUpdater(true)
    autoUpdater.checkForUpdate()

  startLocalhostProxy: ->
    @localhostProxy = new LocalhostProxy(@vmPort)
    @localhostProxy.start()

  deactivate: ->
    @termView = null
    @fsView = null
    @subscriptions.dispose()

    ipc.send 'deactivate-listener'

  cleanup: ->
    if parseInt(localStorage.get('lastFocusedWindow')) == process.pid
      localStorage.delete('lastFocusedWindow')

  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addRightTile(item: @fsView, priority: 5000)

  serialize: ->
    termViewState: @termView.serialize()
    fsViewState: @fsView.serialize()
