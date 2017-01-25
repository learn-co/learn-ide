remote = require 'remote'
BrowserWindow = remote.BrowserWindow
path = require 'path'
compare = require 'semver-compare'
fetch = require './fetch'
config = require './config'
localStorage = require './local-storage'

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


