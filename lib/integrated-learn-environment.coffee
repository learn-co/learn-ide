{CompositeDisposable} = require 'atom'
Terminal = require './models/terminal'
SyncedFS = require './models/synced-fs'
TerminalView = require './views/terminal'
SyncedFSView = require './views/synced-fs'
ipc = require 'ipc'

module.exports =
  config:
    oauthToken:
      type: 'string'
      title: 'OAuth Token'
      description: 'Your learn.co oauth token'
      default: "Paste your learn.co oauth token here"

  termViewState: null
  fsViewState: null
  subscriptions: null

  activate: (state) ->
    @oauthToken = atom.config.get('integrated-learn-environment.oauthToken')

    @term = new Terminal("wss://ile.learn.co:4463?token=" + @oauthToken)
    @termView = new TerminalView(state, @term)

    @fs = new SyncedFS("wss://ile.learn.co:4464?token=" + @oauthToken, @term)
    @fsView = new SyncedFSView(state, @fs)

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'integrated-learn-environment:toggleTerminal': =>
      @termView.toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'integrated-learn-environment:reset': =>
      @term.term.write("\n\r")
      ipc.send 'reset-connection'
      ipc.send 'connection-state-request'

    ipc.on 'remote-log', (msg) ->
      console.log(msg)

  deactivate: ->
    @termView = null
    @fsView = null
    @subscriptions.dispose()

    ipc.send 'deactivate-listener'

  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addRightTile(item: @fsView, priority: 5000)

  serialize: ->
    termViewState: @termView.serialize()
    fsViewState: @fsView.serialize()
