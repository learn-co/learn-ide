{CompositeDisposable} = require 'atom'
TerminalFactory = require './factories/terminal'
TerminalView = require './views/terminal'
WebsocketFactory = require './factories/websocket'
RemoteFileSystem = require './models/remote-file-system'

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
    @term = TerminalFactory.create()
    @termView = new TerminalView(state, @term)

    @fs = new RemoteFileSystem()
    @ws = WebsocketFactory.createWithTerminalLogging("ws://localhost:4463", @term)

    @term.on 'data', (data) =>
      @ws.send data

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'integrated-learn-environment:toggleTerminal': =>
      @termView.toggle()

  deactivate: ->
    @termView.destroy()
    @fsView.destroy()
    @subscriptions.dispose()

  serialize: ->
    termViewState: @termView.serialize()
    fsViewState: @fsView.serialize()