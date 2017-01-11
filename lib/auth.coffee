url = require 'url'
https = require 'https'
remote = require 'remote'
shell = require 'shell'
path = require 'path'
_token = require './token'
BrowserWindow = remote.BrowserWindow

workspaceView = atom.views.getView(atom.workspace)

confirmOauthToken = (token) ->
  return new Promise (resolve, reject) ->
    try
      authRequest = https.get
        host: 'learn.co'
        path: '/api/v1/users/me?ile_version=' + atom.appVersion
        headers:
          'Authorization': 'Bearer ' + token
      , (response) ->
        body = ''

        response.on 'data', (d) ->
          body += d

        response.on 'error', reject

        response.on 'end', ->
          try
            parsed = JSON.parse(body)

            if parsed.email
              resolve parsed
            else
              resolve false
          catch
            reject false

      authRequest.on 'error', (err) ->
        reject err

    catch err
      reject err

githubLogin = () ->
  new Promise (resolve, reject) ->
    win = new BrowserWindow(show: false, width: 440, height: 660, resizable: false)
    webContents = win.webContents

    win.setSkipTaskbar(true)
    win.setMenuBarVisibility(false)
    win.setTitle('Sign in to Github to get started with the Learn IDE')

    # show window only if login is required
    webContents.on 'did-finish-load', -> win.show()

    # hide window immediately after login
    webContents.on 'will-navigate', (e, url) ->
      win.hide() if url.match(/learn\.co\/users\/auth\/github\/callback/)

    webContents.on 'did-get-redirect-request', (e, oldURL, newURL) ->
      return unless newURL.match(/ide_token/)
      token = url.parse(newURL, true).query.ide_token
      confirmOauthToken(token).then (res) ->
        return unless res?
        _token.set(token)
        win.destroy()
        resolve()

    if not win.loadURL('https://learn.co/ide/token?ide_config=true')
      promptManualEntry()

window.learnSignIn = () ->
  new Promise (resolve, reject) ->
    win = new BrowserWindow(show: false, width: 400, height: 600, resizable: false)
    {webContents} = win

    win.setSkipTaskbar(true)
    win.setMenuBarVisibility(false)
    win.setTitle('Welcome to the Learn IDE')

    webContents.on 'did-finish-load', -> win.show()

    webContents.on 'new-window', (e, url) ->
      e.preventDefault()
      win.destroy()
      shell.openExternal(url)

    webContents.on 'will-navigate', (e, url) ->
      if url.match(/github_sign_in/)
        win.destroy()
        githubLogin().then(resolve)

    webContents.on 'did-get-redirect-request', (e, oldURL, newURL) ->
      if newURL.match(/ide_token/)
        token = url.parse(newURL, true).query.ide_token
        if token?.length
          confirmOauthToken(token).then (res) ->
            return unless res
            _token.set(token)
            resolve()
      if newURL.match(/github_sign_in/)
        win.destroy()
        githubLogin().then(resolve)

    if not win.loadURL('https://learn.co/ide/sign_in?ide_onboard=true')
      win.destroy()
      githubLogin.then(resolve)

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
          _token.set(token)
          panel.destroy()
          atom.commands.dispatch(workspaceView, 'learn-ide:toggle-terminal')
          return true
        else
          invalidLabel.setAttribute 'style', 'color: red; opacity: 100;'

githubLogout = ->
  win = new BrowserWindow(show: false)
  win.webContents.on 'did-finish-load', -> win.show()
  win.loadURL('https://github.com/logout')

learnLogout = ->
  win = new BrowserWindow(show: false)
  win.webContents.on 'did-finish-load', -> win.destroy()
  win.loadURL('https://learn.co/sign_out')

window.logout = ->
  _token.unset()
  learnLogout()
  githubLogout()

module.exports = ->
  existingToken = _token.get()

  if !existingToken
    learnSignIn()
  else
    confirmOauthToken(existingToken)
