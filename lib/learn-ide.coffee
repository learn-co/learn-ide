_ = require 'underscore-plus'
path = require 'path'
ipc = require 'ipc'
localStorage = require './local-storage'
{CompositeDisposable} = require 'atom'
Terminal = require './models/terminal'
TerminalView = require './views/terminal'
StatusView = require './views/status'
{EventEmitter} = require 'events'
Updater = require './models/learn-updater'
LocalhostProxy = require './models/localhost-proxy'
WebWindow = require './models/web-window'
bus = require('./event-bus')()
Notifier = require './notifier.coffee'
atomHelper = require './atom-helper'

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

    @oauthToken = atom.config.get('learn-ide.oauthToken')
    @vmPort = atom.config.get('learn-ide.vmPort')
      
    @activateTerminal()
    @activateStatusView(state)
    @activateEventHandlers()
    @activateSubscriptions()
    @activateLocalhostProxy()
    @activateNotifier()
    @activateUpdater()

  activateTerminal: ->
    @isTerminalWindow = (localStorage.get('popoutTerminal') == 'true')

    if @isTerminalWindow
      window.resizeTo(750, 500)
      localStorage.delete('popoutTerminal')

    @term = new Terminal("#{WS_SERVER_URL}/go_terminal_server?token=#{@oauthToken}")
    @termView = new TerminalView(@term, null, @isTerminalWindow)

    if @isTerminalWindow
      document.getElementsByClassName('terminal-view-resize-handle')[0].setAttribute('style', 'display:none;')
      # document.getElementsByClassName('inset-panel')[0].setAttribute('style', 'display:none;')
      document.getElementsByClassName('learn-terminal')[0].style.height = '448px'
      workspaceView = atom.views.getView(atom.workspace)
      atom.commands.dispatch(workspaceView, 'tree-view:toggle')

    @termView.toggle()

  activateStatusView: (state) ->
    @statusView = new StatusView state, @term, {isTerminalWindow: @isTerminalWindow}

    bus.on 'terminal:popin', () =>
      @statusView.onTerminalPopIn()
      @termView.toggle()

    @statusView.on 'terminal:popout', =>
      @termView.toggle()

  activateEventHandlers: ->
    # keep track of the focused window's pid
    atomHelper.setLastFocusedWindow()
    window.onfocus = atomHelper.setLastFocusedWindow

    # listen for learn:open event from other render processes (url handler)
    bus.on 'learn:open', (lab) =>
      @termView.openLab(lab.slug)
      atom.getCurrentWindow().focus()

    # tidy up when the window closes
    atom.getCurrentWindow().on 'close', =>
      @cleanup()
      if @isTerminalWindow
        bus.emit('terminal:popin', Date.now())

  activateSubscriptions: ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace',
      'learn-ide:open': (e) => @termView.openLab(e.detail.path)
      'learn-ide:toggle-terminal': () => @termView.toggle()
      'learn-ide:toggle-focus': => @termView.toggleFocus()
      'learn-ide:reset': =>
        @term.term.write('\n\rReconnecting...\r')
        ipc.send 'reset-connection'
        ipc.send 'connection-state-request'
      'application:update-ile': -> (new Updater).checkForUpdate()

    openPath = localStorage.get('learnOpenLabOnActivation')
    if openPath
      localStorage.delete('learnOpenLabOnActivation')
      @termView.openLab(openPath)


  activateLocalhostProxy: ->
    @localhostProxy = new LocalhostProxy(@vmPort)
    @localhostProxy.activate()

  activateNotifier: ->
    @notifier = new Notifier(@oauthToken)
    @notifier.activate()

  activateUpdater: ->
    @updater = new Updater(true)
    @updater.checkForUpdate()

  # activateIDE: ->
    # TODO: to remove, left for reference of remaining logic that needs to be reimplemented

    # ipc.on 'learn-submit-alert', (event) ->
      # new WebWindow(event.file, resizable: false)

    # ipc.on 'in-app-notification', (notifData) =>
      # atom.notifications['add' + notifData.type.charAt(0).toUpperCase() + notifData.type.slice(1)] notifData.message, {detail: notifData.detail, dismissable: notifData.dismissable}


  deactivate: ->
    @termView = null
    @statusView = null
    @subscriptions.dispose()

    ipc.send 'deactivate-listener'

  cleanup: ->
    if atomHelper.isLastFocusedWindow()
      localStorage.delete('lastFocusedWindow')

  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addRightTile(item: @statusView, priority: 5000)

  serialize: ->
    termViewState: @termView.serialize()
    fsViewState: @statusView.serialize()
