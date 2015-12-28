{CompositeDisposable} = require 'atom'
TerminalFactory = require './factories/terminal'
TerminalView = require './views/terminal'
WebsocketFactory = require './factories/websocket'
SyncedFS = require './models/synced-fs'

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
    @termWebsocket = WebsocketFactory.createWithTerminalLogging("ws://localhost:4463", @term)
    @term.on 'data', (data) =>
      @termWebsocket.send data

    @fs = new SyncedFS()
    @fsWebsocket = WebsocketFactory.createWithFSLogging("ws://localhost:4464", @term)
    atom.workspace.observeTextEditors (editor) =>
      console.log(editor)
      editor.onDidSave =>
        buffer = editor.buffer
        @fsWebsocket.send(buffer.file.path + ":" + buffer.file.digest + ":" + buffer.getText())
        atom.notifications.addSuccess("Synced " + buffer.getBaseName())

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
