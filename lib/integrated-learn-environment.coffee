TerminalView = require './terminal-view'
{CompositeDisposable} = require 'atom'

module.exports = IntegratedLearnEnvironment =
  terminalViewState: null
  terminalPanel: null
  subscriptions: null

  activate: (state) ->
    @terminalView = new TerminalView(state.terminalViewState)

    @terminalPanel = atom.workspace.addBottomPanel(item: @terminalView, visible: false, className: 'ile-terminal-view')

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
