IntegratedLearnEnvironmentView = require './integrated-learn-environment-view'
{CompositeDisposable} = require 'atom'

module.exports = IntegratedLearnEnvironment =
  integratedLearnEnvironmentView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @integratedLearnEnvironmentView = new IntegratedLearnEnvironmentView(state.integratedLearnEnvironmentViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @integratedLearnEnvironmentView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'integrated-learn-environment:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @integratedLearnEnvironmentView.destroy()

  serialize: ->
    integratedLearnEnvironmentViewState: @integratedLearnEnvironmentView.serialize()

  toggle: ->
    console.log 'IntegratedLearnEnvironment was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
