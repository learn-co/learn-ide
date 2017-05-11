localStorage = require './local-storage'
{CompositeDisposable} = require 'atom'
Terminal = require './terminal'
TerminalView = require './terminal-view'
StatusView = require './views/status'
Notifier = require './notifier'
airbrake = require './airbrake'
atomHelper = require './atom-helper'
auth = require './auth'
bus = require './event-bus'
config = require './config'
{shell} = require 'electron'
updater = require './updater'
version = require './version'
remoteNotification = require './remote-notification'
{name} = require '../package.json'
colors = require './colors'
logout = require './logout'

ABOUT_URL = "#{config.learnCo}/ide/about"

module.exports =
  token: require('./token')

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @activateMonitor()
    @checkForV1WindowsInstall()
    @registerWindowsProtocol()
    @disableFormerPackage()
    colors.apply()

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

    @termView = new TerminalView(@term)

  activateStatusView: (state) ->
    @statusView = new StatusView(state, @term)

  activateEventHandlers: ->
    atomHelper.trackFocusedWindow()

    # listen for learn:open event from other render processes (url handler)
    bus.on 'learn:open', (lab) =>
      @learnOpen(lab.slug)
      atom.getCurrentWindow().focus()

    # tidy up when the window closes
    atom.getCurrentWindow().on 'close', =>
      @cleanup()

  activateSubscriptions: ->
    @subscriptions.add atom.commands.add 'atom-workspace',
      'learn-ide:open': (e) => @learnOpen(e.detail.path)
      'learn-ide:toggle-terminal': () => @termView.toggle()
      'learn-ide:toggle-popout': () => @termView.focusPopoutEmulator()
      'learn-ide:toggle-focus': => @termView.toggleFocus()
      'learn-ide:focus': => @termView.focusEmulator()
      'learn-ide:toggle:debugger': => @term.toggleDebugger()
      'learn-ide:reset-connection': => @term.reset()
      'learn-ide:view-version': => @viewVersion()
      'learn-ide:update-check': -> updater.checkForUpdate()
      'learn-ide:about': => @about()

    @subscriptions.add atom.commands.add '.terminal',
      'core:copy': => @termView.clipboardCopy()
      'core:paste': => @termView.clipboardPaste()
      'learn-ide:reset-font-size': => @termView.resetFontSize()
      'learn-ide:increase-font-size': => @termView.increaseFontSize()
      'learn-ide:decrease-font-size': => @termView.decreaseFontSize()
      'learn-ide:clear-terminal': => @term.send('')

    atom.config.onDidChange "#{name}.terminalColors.basic", =>
      colors.apply()

    atom.config.onDidChange "#{name}.terminalColors.ansi", =>
      colors.apply()

    atom.config.onDidChange "#{name}.terminalColors.json", ({newValue}) =>
      colors.parseJSON(newValue)

    atom.config.onDidChange "#{name}.notifier", ({newValue}) =>
      if newValue then @activateNotifier() else @notifier.deactivate()

    openPath = localStorage.get('learnOpenLabOnActivation')
    if openPath
      localStorage.delete('learnOpenLabOnActivation')
      @learnOpen(openPath)

  activateNotifier: ->
    if atom.config.get("#{name}.notifier")
      @notifier = new Notifier(@token.get())
      @notifier.activate()

  activateUpdater: ->
    if not @isRestartAfterUpdate
      updater.autoCheck()

  activateMonitor: ->
   @subscriptions.add atom.onWillThrowError ({originalError}) =>
     airbrake.notify(originalError)

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
      logout()
    else
      atomHelper.resetPackage()

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

    priority = (rightMostTile?.priority || 0) - 1
    statusBar.addRightTile({item: @statusView, priority})

  learnOpen: (labSlug) ->
    if labSlug?
      @term.send("learn open #{labSlug.toString()}\r")

  about: ->
    shell.openExternal(ABOUT_URL)

  viewVersion: ->
    atom.notifications.addInfo("Learn IDE: v#{version}")

