{BufferedProcess} = require 'atom'
compare = require 'semver-compare'
config = require './config'
fetch = require './fetch'
localStorage = require './local-storage'

LATEST_VERSION_URL = "#{config.learnCo}/api/v1/learn_ide/latest_version"

module.exports =
  autoCheck: ->
    if not @_shouldSkipCheck()
      fetch(LATEST_VERSION_URL).then ({version}) =>
        @_setCheckDate()

        if @_shouldUpdate(version)
          @_addUpdateNotification()

  checkForUpdate: ->
    fetch(LATEST_VERSION_URL).then ({version}) =>
      @_setCheckDate()

      if @_shouldUpdate(version)
        @_addUpdateNotification()
      else
        @_addUpToDateNotification()

  update: ->
    @_updateOrInstallDependencies().then (data) =>
      @_afterUpdate(data)

  _setCheckDate: ->
    localStorage.set('updateCheckDate', Date.now())

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

  _addUpdateNotification: ->
    @_updateNotification =
      atom.notifications.addInfo 'Learn IDE: update available!',
        description: "You're gonna want this new hotness"
        dismissable: true
        buttons: [
          text: 'Install update'
          onDidClick: => @update()
        ]

  _addUpToDateNotification: ->
    atom.notifications.addSuccess 'Learn IDE: up-to-date!'

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
    @_updateNotification?.dismiss()

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
    atom.notifications.addSuccess 'Learn IDE: update installed',
      detail: log
      description: 'Restart to activate hotness'
      dismissable: true
      buttons: [
        text: 'Restart the editor'
        onDidClick: -> atom.restartApplication()
      ]

