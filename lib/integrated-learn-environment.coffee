{CompositeDisposable} = require 'atom'
term = require 'term.js'
WebsocketFactory = require './websocket-factory'
TerminalView = require './views/terminal-view'
TerminalController = require './controllers/terminal-controller'

module.exports = IntegratedLearnEnvironment =
  terminalViewState: null
  terminalPanel: null
  terminalController: null
  subscriptions: null

  activate: (state) ->
    @terminal = new term.Terminal(useStyle: no, screenKeys: no)

    @terminalView = new TerminalView(@terminal)
    @terminalPanel = atom.workspace.addBottomPanel(item: @terminalView, visible: false, className: 'ile-terminal-view')

    @ws = WebsocketFactory.createWithTerminalLogging("ws://localhost:4463", @terminal)
    @terminalController = new TerminalController(@ws, @terminal)

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'integrated-learn-environment:toggleTerminal': => @toggleTerminal()

  deactivate: ->
    @terminalPanel.destroy()
    @terminalView.destroy()
    @subscriptions.dispose()

  serialize: ->
    terminalViewState: @terminalView.serialize()

  toggleTerminal: ->
    console.log 'Toggled terminalPanel'

    if @terminalPanel.isVisible()
      @terminalPanel.hide()
    else
      @terminalPanel.show()
