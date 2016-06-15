url = require 'url'
https = require 'https'
remote = require 'remote'
BrowserWindow = remote.require('browser-window')

workspaceView = atom.views.getView(atom.workspace)
atom.commands.dispatch(workspaceView, 'tree-view:show')
atom.project.setPaths([atom.getUserWorkingDirPath()])

confirmOauthToken = (token) ->
  return new Promise((resolve, reject) ->
    https.get
      host: 'learn.co'
      path: '/api/v1/users/me?ile_version=' + atom.appVersion
      headers:
        'Authorization': 'Bearer ' + token
    , (response) ->
      body = ''

      response.on 'data', (d) ->
        body += d

      response.on 'error', ->
        resolve false

      response.on 'end', ->
        try
          parsed = JSON.parse(body)
          console.log parsed

          if parsed.username
            resolve parsed
          else
            resolve false
        catch
          resolve false
  )

getTokenAndVMPort = ->
  win = new BrowserWindow(show: false, width: 1040, height: 660)
  win.setSkipTaskbar(true)
  win.setAlwaysOnTop(true)
  win.setClosable(false)
  win.setMinimizable(false)
  win.setTitle('Sign in to Github to get started with the Learn IDE')

  webContents = win.webContents
  webContents.on 'did-finish-load', -> win.show()
  webContents.on 'did-get-redirect-request', (e, oldURL, newURL) ->
    if newURL.match(/ide_token/)
      token = url.parse(newURL, true).query.ide_token
      confirmOauthToken(token).then (res) ->
        if res
          atom.config.set('integrated-learn-environment.oauthToken', token)
          atom.config.set('integrated-learn-environment.vm_port', res.vm_uid)
          win.destroy()

          atom.commands.dispatch(workspaceView, 'integrated-learn-environment:toggleTerminal')
        else

  promptManualEntry() unless win.loadUrl('https://learn.co/ide/token?ide_config=true')

promptManualEntry = ->
  oauthPrompt = document.createElement 'div'
  oauthPrompt.setAttribute 'style', 'width:100%; text-align: center;'

  oauthLabel = document.createElement 'div'
  oauthLabel.setAttribute 'style', 'margin-top: 12px; font-weight: bold; font-size: 12px;'
  oauthLabel.appendChild document.createTextNode 'Please enter your Learn OAuth Token'
  tokenLinkDiv = document.createElement 'div'
  tokenText = document.createTextNode 'Get your token here: '
  tokenLink = document.createElement 'a'
  tokenLink.title = 'https://learn.co/ide/token'
  tokenLink.href = 'https://learn.co/ide/token'
  tokenLink.setAttribute 'style', 'text-decoration: underline;'
  tokenLink.appendChild document.createTextNode 'https://learn.co/ide/token'
  tokenLinkDiv.appendChild tokenText
  tokenLinkDiv.appendChild tokenLink
  oauthPrompt.appendChild oauthLabel
  oauthLabel.appendChild tokenLinkDiv

  invalidLabel = document.createElement 'label'
  invalidLabel.setAttribute 'style', 'opacity: 0;'
  invalidLabel.appendChild document.createTextNode 'Invalid token. Please try again.'
  oauthPrompt.appendChild invalidLabel
  input = document.createElement 'input'
  input.setAttribute 'style', 'width: 100%; text-align: center;'
  input.classList.add 'native-key-bindings'
  oauthPrompt.appendChild input

  panel = atom.workspace.addModalPanel item: oauthPrompt
  input.focus()

  input.addEventListener 'keypress', (e) =>
    if e.which is 13
      token = input.value.trim()
      confirmOauthToken(token).then (res) ->
        if res
          atom.config.set('integrated-learn-environment.oauthToken', input.value)
          atom.config.set('integrated-learn-environment.vm_port', res.vm_uid)
          panel.destroy()
          atom.commands.dispatch(workspaceView, 'integrated-learn-environment:toggleTerminal')
          return true
        else
          invalidLabel.setAttribute 'style', 'color: red; opacity: 100;'

getVMPort = ->
  confirmOauthToken(existingToken).then (res) ->
    if res
      atom.config.set('integrated-learn-environment.vm_port', res.vm_uid)
      atom.commands.dispatch(workspaceView, 'integrated-learn-environment:toggleTerminal')
      return true

existingToken = atom.config.get('integrated-learn-environment.oauthToken')
vmPort = atom.config.get('integrated-learn-environment.vm_port')

if !existingToken
  getTokenAndVMPort()
else if !vmPort
  getVMPort()
else
  atom.commands.dispatch(workspaceView, 'integrated-learn-environment:toggleTerminal')
  confirmOauthToken(existingToken)
