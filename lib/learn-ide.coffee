localStorage = require './local-storage'
{CompositeDisposable} = require 'atom'
Terminal = require './terminal'
TerminalView = require './views/terminal'
StatusView = require './views/status'
{EventEmitter} = require 'events'
Updater = require './updater'
bus = require('./event-bus')()
Notifier = require './notifier'
atomHelper = require './atom-helper'
config = require './config'
auth = require './auth'
remote = require 'remote'
BrowserWindow = remote.require('browser-window')

module.exports =
  activate: (state) ->
    @loadCredentials()

    auth().then =>
      @loadCredentials()
      if not @term.isConnected
        @term.updateToken(@oauthToken)
        @term.connect()


    @isTerminalWindow = (localStorage.get('popoutTerminal') == 'true')
    if @isTerminalWindow
      window.resizeTo(750, 500)
      localStorage.delete('popoutTerminal')

    @activateTerminal()
    @activateStatusView(state)
    @activateEventHandlers()
    @activateSubscriptions()
    @activateNotifier()
    @activateUpdater()

  activateTerminal: ->
    @term = new Terminal
      host: config.host,
      port: config.port,
      token: @oauthToken

    @termView = new TerminalView(@term, null, @isTerminalWindow)
    @termView.toggle()

  activateStatusView: (state) ->
    @statusView = new StatusView state, @term, {@isTerminalWindow}

    bus.on 'terminal:popin', () =>
      @statusView.onTerminalPopIn()
      @termView.toggle()

    @statusView.on 'terminal:popout', =>
      @termView.toggle()

  activateEventHandlers: ->
    atomHelper.trackFocusedWindow()

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
      'learn-ide:logout': => @logout()
      'learn-ide:reset': =>
        @term.term.write('\n\rReconnecting...\r')
      'application:update-ile': -> (new Updater).checkForUpdate()

    openPath = localStorage.get('learnOpenLabOnActivation')
    if openPath
      localStorage.delete('learnOpenLabOnActivation')
      @termView.openLab(openPath)


  activateNotifier: ->
    @notifier = new Notifier(@oauthToken)
    @notifier.activate()

  activateUpdater: ->
    @updater = new Updater(true)
    @updater.checkForUpdate()

  deactivate: ->
    localStorage.delete('disableTreeView')
    @termView = null
    @statusView = null
    @subscriptions.dispose()

  cleanup: ->
    atomHelper.cleanup()

  loadCredentials: ->
    @oauthToken = atom.config.get('learn-ide.oauthToken')
    @vmPort = atom.config.get('learn-ide.vmPort')

  consumeStatusBar: (statusBar) ->
    statusBar.addRightTile(item: @statusView, priority: 5000)

  serialize: ->
    termViewState: @termView.serialize()
    fsViewState: @statusView.serialize()

  logout: ->
    atom.config.unset('learn-ide.oauthToken')

    github = new BrowserWindow(show: false)
    github.webContents.on 'did-finish-load', -> github.show()
    github.loadUrl('https://github.com/logout')

    learn = new BrowserWindow(show: false)
    learn.webContents.on 'did-finish-load', -> learn.destroy()
    learn.loadUrl('https://learn.co/sign_out')

    atom.reload()

