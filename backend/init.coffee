workspaceView = atom.views.getView(atom.workspace)
atom.commands.dispatch(workspaceView, 'tree-view:show')
atom.project.setPaths([atom.getUserWorkingDirPath()])

if !atom.config.get('integrated-learn-environment.oauthToken')
  oauthPrompt = document.createElement "div"
  oauthPrompt.setAttribute 'style', 'width:100%; text-align: center;'

  oauthLabel = document.createElement "div"
  oauthLabel.setAttribute 'style', 'margin-bottom: 20px; margin-top: 12px; font-weight: bold; font-size: 12px;'
  oauthLabel.appendChild document.createTextNode 'Please enter your Learn OAuth Token'
  tokenLinkDiv = document.createElement "div"
  tokenText = document.createTextNode 'Get your token here: '
  tokenLink = document.createElement "a"
  tokenLink.title = 'https://learn.co/ile/token'
  tokenLink.href = 'https://learn.co/ile/token'
  tokenLink.setAttribute 'style', 'text-decoration: underline;'
  tokenLink.appendChild document.createTextNode 'https://learn.co/ile/token'
  tokenLinkDiv.appendChild tokenText
  tokenLinkDiv.appendChild tokenLink
  oauthPrompt.appendChild oauthLabel
  oauthLabel.appendChild tokenLinkDiv

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
