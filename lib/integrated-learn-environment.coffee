{CompositeDisposable} = require 'atom'
Terminal = require './models/terminal'
TerminalView = require './views/terminal'
SyncedFS = require './models/synced-fs'

module.exports =
  config:
    oauthToken:
      type: 'string'
      title: 'OAuth Token'
      description: 'Your learn.co oauth token'
      default: "Paste your learn.co oauth token here"

  termViewState: null
  subscriptions: null

  activate: (state) ->
    @term = new Terminal("ws://localhost:4463")
    @termView = new TerminalView(state, @term)

    @fs = new SyncedFS("ws://localhost:4464", @term)

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'integrated-learn-environment:toggleTerminal': =>
      @termView.toggle()

  deactivate: ->
    @termView.destroy()
    @subscriptions.dispose()

  serialize: ->
    termViewState: @termView.serialize()
