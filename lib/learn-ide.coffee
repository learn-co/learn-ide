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
  token: require('./token')

  activate: (state) ->
    console.log 'activating learn ide'
    @checkForV1WindowsInstall()
    @registerWindowsProtocol()
    @disableFormerPackage()

    @subscriptions = new CompositeDisposable
    @subscribeToLogin()

    @waitForAuth = auth().then =>
      @activateIDE(state)
      console.log('successfully authenticated')
    .catch =>
      @activateIDE(state)
      console.error('failed to authenticate')

  activateIDE: (state) ->
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
      host: config.host
      port: config.port
      path: config.path
      token: @token.get()

    @termView = new TerminalView(@term, null, @isTerminalWindow)
    @termView.toggle()

  activateStatusView: (state) ->
    @statusView = new StatusView state, @term, {@isTerminalWindow}

    bus.on 'terminal:popin', () =>
      @statusView.onTerminalPopIn()
      @termView.showAndFocus()

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
    @subscriptions.add atom.commands.add 'atom-workspace',
      'learn-ide:open': (e) => @termView.openLab(e.detail.path)
      'learn-ide:toggle-terminal': () => @termView.toggle()
      'learn-ide:toggle-focus': => @termView.toggleFocus()
      'learn-ide:focus': => @termView.fullFocus()
      'learn-ide:toggle:debugger': => @term.toggleDebugger()
      'learn-ide:reset': => @term.reset()
      'application:update-ile': -> (new Updater).checkForUpdate()

    atom.config.onDidChange 'learn-ide.notifier', ({newValue}) =>
      if newValue then @activateNotifier() else @notifier.deactivate()

    openPath = localStorage.get('learnOpenLabOnActivation')
    if openPath
      localStorage.delete('learnOpenLabOnActivation')
      @termView.openLab(openPath)


  activateNotifier: ->
    if atom.config.get('learn-ide.notifier')
      @notifier = new Notifier(@token.get())
      @notifier.activate()

  activateUpdater: ->
    @updater = new Updater(true)
    @updater.checkForUpdate()

  deactivate: ->
    localStorage.delete('disableTreeView')
    localStorage.delete('terminalOut')
    @termView = null
    @statusView = null
    @subscriptions.dispose()

  subscribeToLogin: ->
    @subscriptions.add atom.commands.add 'atom-workspace',
      'learn-ide:log-in-out': => @logInOrOut()

  cleanup: ->
    atomHelper.cleanup()

  consumeStatusBar: (statusBar) ->
    @waitForAuth.then =>
      statusBar.addRightTile(item: @statusView, priority: 5000)

  logInOrOut: ->
    if @token.get()?
      @logout()
    else
      atomHelper.resetPackage()

  logout: ->
    @token.unset()

    github = new BrowserWindow(show: false)
    github.webContents.on 'did-finish-load', -> github.show()
    github.loadURL('https://github.com/logout')

    learn = new BrowserWindow(show: false)
    learn.webContents.on 'did-finish-load', -> learn.destroy()
    learn.loadURL('https://learn.co/sign_out')

    atomHelper.emit('learn-ide:logout')
    atomHelper.closePaneItems()
    atom.reload()

  checkForV1WindowsInstall: ->
    require('./windows')

  registerWindowsProtocol: ->
    if process.platform == 'win32'
      require('./protocol')

  disableFormerPackage: ->
    ilePkg = atom.packages.loadPackage('integrated-learn-environment')

    if ilePkg?
      ilePkg.disable()

