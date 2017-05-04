localStorage = require './local-storage'
{CompositeDisposable} = require 'atom'
Terminal = require './terminal'
TerminalView = require './views/terminal'
StatusView = require './views/status'
{BrowserWindow} = require 'remote'
Notifier = require './notifier'
airbrake = require './airbrake'
atomHelper = require './atom-helper'
auth = require './auth'
bus = require('./event-bus')()
config = require './config'
{shell} = require 'electron'
updater = require './updater'
version = require './version'
handleErrorNotifications = require './handle-error'
remoteNotification = require './remote-notification'
{name} = require '../package.json'

ABOUT_URL = "#{config.learnCo}/ide/about"

module.exports =
  token: require('./token')

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @activateMonitor()
    @checkForV1WindowsInstall()
    @registerWindowsProtocol()
    @disableFormerPackage()

    @subscribeToLogin()

    @waitForAuth = auth().then =>
      @activateIDE(state)
      console.log('successfully authenticated')
    .catch =>
      @activateIDE(state)
      console.error('failed to authenticate')

  activateIDE: (state) ->
    @isRestartAfterUpdate = (localStorage.get('restartingForUpdate') is 'true')
    if @isRestartAfterUpdate
      updater.didRestartAfterUpdate()
      localStorage.delete('restartingForUpdate')

    @isTerminalWindow = (localStorage.get('popoutTerminal') is 'true')
    if @isTerminalWindow
      window.resizeTo(750, 500)
      localStorage.delete('popoutTerminal')

    @activateTerminal()
    @activateStatusView(state)
    @activateEventHandlers()
    @activateSubscriptions()
    @activateNotifier()
    @activateUpdater()
    @activateRemoteNotification()

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
      'learn-ide:reset-connection': => @term.reset()
      'learn-ide:view-version': => @viewVersion()
      'learn-ide:update-check': -> updater.checkForUpdate()
      'learn-ide:about': => @about()

    atom.config.onDidChange "#{name}.terminalFontColor", ({newValue}) =>
      @termView.updateFontColor(newValue)

    atom.config.onDidChange "#{name}.terminalBackgroundColor", ({newValue}) =>
      @termView.updateBackgroundColor(newValue)

    atom.config.onDidChange "#{name}.notifier", ({newValue}) =>
      if newValue then @activateNotifier() else @notifier.deactivate()

    openPath = localStorage.get('learnOpenLabOnActivation')
    if openPath
      localStorage.delete('learnOpenLabOnActivation')
      @termView.openLab(openPath)


  activateNotifier: ->
    if atom.config.get("#{name}.notifier")
      @notifier = new Notifier(@token.get())
      @notifier.activate()

  activateUpdater: ->
    if not @isRestartAfterUpdate
      updater.autoCheck()

  activateMonitor: ->
   @subscriptions.add atom.onWillThrowError (err) =>
     airbrake.notify(err.originalError)
     handleErrorNotifications(err)

  activateRemoteNotification: ->
    remoteNotification()

  deactivate: ->
    localStorage.delete('disableTreeView')
    localStorage.delete('terminalOut')
    @termView = null
    @statusView = null
    @subscriptions.dispose()
    @term.removeAllListeners()

  subscribeToLogin: ->
    @subscriptions.add atom.commands.add 'atom-workspace',
      'learn-ide:log-in-out': => @logInOrOut()

  cleanup: ->
    atomHelper.cleanup()

  consumeStatusBar: (statusBar) ->
    @waitForAuth.then => @addLearnToStatusBar(statusBar)

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
    learn.loadURL("#{config.learnCo}/sign_out")

    atomHelper.emit('learn-ide:logout')
    atomHelper.closePaneItems()
    atom.reload()

  checkForV1WindowsInstall: ->
    require('./windows')

  registerWindowsProtocol: ->
    if process.platform == 'win32'
      require('./protocol')

  disableFormerPackage: ->
    pkgName = 'integrated-learn-environment'

    if not atom.packages.isPackageDisabled(pkgName)
      atom.packages.disablePackage(pkgName)

  addLearnToStatusBar: (statusBar) ->
    leftTiles = Array.from(statusBar.getLeftTiles())
    rightTiles = Array.from(statusBar.getRightTiles())
    rightMostTile = rightTiles[rightTiles.length - 1]

    if @isTerminalWindow
      leftTiles.concat(rightTiles).forEach (tile) ->
        tile.destroy()

    priority = (rightMostTile?.priority || 0) - 1
    statusBar.addRightTile({item: @statusView, priority})

  about: ->
    shell.openExternal(ABOUT_URL)

  viewVersion: ->
    atom.notifications.addInfo("Learn IDE: v#{version}")

