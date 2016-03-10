#oauthToken = 'd5c31f1ef9e4f734fc42be436724049a22bdfe4cbf92671389e843e4ff114fe6'

workspaceView = atom.views.getView(atom.workspace)
atom.commands.dispatch(workspaceView, 'tree-view:show')
atom.project.setPaths([atom.getUserWorkingDirPath()])

if !atom.config.get('integrated-learn-environment.oauthToken')
  #oauthToken = prompt('Please enter your Learn OAuth Token')
  #atom.config.set('integrated-learn-environment.oauthToken', oauthToken)
  oauthPrompt = document.createElement "div"
  oauthPrompt.setAttribute 'style', 'width:100%; text-align: center;'

  oauthLabel = document.createElement "div"
  oauthLabel.setAttribute 'style', 'margin-bottom: 10px; font-weight:bold; font-size:12px;'
  oauthLabel.appendChild document.createTextNode 'Please enter your Learn OAuth Token'
  oauthPrompt.appendChild oauthLabel

  input = document.createElement 'input'
  input.setAttribute 'style', 'width:100%; text-align: center;'
  input.classList.add 'native-key-bindings'
  oauthPrompt.appendChild input

  panel = atom.workspace.addModalPanel item: oauthPrompt
  input.focus()

  input.addEventListener 'keypress', (e) =>
    if e.which is 13
      atom.config.set('integrated-learn-environment.oauthToken', input.value)
      panel.destroy()
      atom.commands.dispatch(workspaceView, 'integrated-learn-environment:toggleTerminal')
      return false
else
  atom.commands.dispatch(workspaceView, 'integrated-learn-environment:toggleTerminal')
