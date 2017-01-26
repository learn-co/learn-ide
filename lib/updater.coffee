{BrowserWindow} = require 'remote'
{BufferedProcess} = require 'atom'
compare = require 'semver-compare'
config = require './config'
fetch = require './fetch'
localStorage = require './local-storage'
path = require 'path'

UPDATE_WINDOW_URL = "file://#{path.resolve(__dirname, '..', 'static', 'update_check.html')}"
LATEST_VERSION_URL = "#{config.learnCo}/api/v1/learn_ide/latest_version"

module.exports =
  autoCheck: ->
    return if @_shouldSkipCheck()

    fetch(LATEST_VERSION_URL).then (latest) =>
      if @_shouldUpdate(latest.version)
        @_openUpdateCheck(latest)
      else
        localStorage.set('updateCheckDate', Date.now())

  checkForUpdate: ->
    fetch(LATEST_VERSION_URL).then (latest) =>
      @_openUpdateCheck(latest)

  update: ->
    @_updateOrInstallDependencies().then (data) =>
      @_afterUpdate(data)

  _getPackageDependencies: ->
    pkg = require('../package.json')
    Object.keys(pkg.packageDependencies)

  _shouldUpdate: (latestVersion) ->
    currentVersion = require './version'
    compare(latestVersion, currentVersion) is 1

  _shouldSkipCheck: ->
    oneDay = 24 * 60 * 60
    @_lastCheckedAgo() < oneDay

  _lastCheckedAgo: ->
    checked = parseInt(localStorage.get('updateCheckDate'))
    Date.now() - checked

  _openUpdateCheck: (latest) ->
    @_setLocalStorage(latest)

    win = new BrowserWindow
      show: false
      width: 500
      height: 250
      resizable: false
      title: 'Update Learn IDE'

    win.loadURL(UPDATE_WINDOW_URL)
    win.once 'ready-to-show', ->
        win.show()

  _setLocalStorage: (latest) ->
    {win, mac} = latest.download_urls
    downloadURL = if process.platform is 'win32' then win else mac

    data = JSON.stringify
      downloadURL: downloadURL
      outOfDate: @_shouldUpdate(latest.version)

    localStorage.set('updateCheck', data)
    localStorage.set('updateCheckDate', Date.now())

  _updateOrInstallDependencies: ->
    new Promise (resolve) =>
      log = ''
      packages = @_getPackageDependencies()

      new BufferedProcess
       command: atom.packages.getApmPath()
       args: ['upgrade', '--no-confirm', '--no-color'].concat(packages)
       stdout: (data) -> log += data
       exit: (code) -> resolve({log, code})

  _afterUpdate: ({log, code}) ->
    callback = if code is 0 then @_updateSucceeded else @_updateFailed
    callback(log)

  _updateFailed: (log) ->
    atom.notifications.addWarning 'Learn IDE: failed to update',
      detail: log
      description: 'Please pass this info along to support'
      dismissable: true
      buttons: [
        text: 'Copy this log'
        onDidClick: ->
          {clipboard} = require 'electron'
          clipboard.writeText(log)
      ]

  _updateSucceeded: (log) ->
    atom.notifications.addSuccess 'Learn IDE: updates installed',
      detail: log
      description: 'Restart to get the new hotness'
      dismissable: true
      buttons: [
        text: 'Restart now'
        onDidClick: -> atom.restartApplication()
      ]

