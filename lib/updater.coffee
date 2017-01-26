{BufferedProcess} = require 'atom'
compare = require 'semver-compare'
config = require './config'
fetch = require './fetch'
localStorage = require './local-storage'

LATEST_VERSION_URL = "#{config.learnCo}/api/v1/learn_ide/latest_version"

module.exports =
  autoCheck: ->
    if not @_shouldSkipCheck()
      fetch(LATEST_VERSION_URL).then ({version, detail}) =>
        @_setCheckDate()

        if @_shouldUpdate(version)
          @_addUpdateNotification(detail)

  checkForUpdate: ->
    fetch(LATEST_VERSION_URL).then ({version, detail}) =>
      @_setCheckDate()

      if @_shouldUpdate(version)
        @_addUpdateNotification(detail)
      else
        @_addUpToDateNotification()

  update: ->
    @_updateOrInstallDependencies().then (result) ->
      localStorage.set('updateResult', JSON.stringify(result))
      localStorage.set('restartingForUpdate', true)
      atom.restartApplication()

  didRestartAfterUpdate: ->
    updateResult = JSON.parse(localStorage.get('updateResult'))
    if updateResult?
      @_afterUpdate(updateResult)

  _setCheckDate: ->
    localStorage.set('updateCheckDate', Date.now())

  _getPackageDependencies: ->
    pkg = require('../package.json')
    Object.keys(pkg.packageDependencies)

  _shouldUpdate: (latestVersion) ->
    currentVersion = require './version'
    compare(latestVersion, currentVersion) is 1

  _shouldSkipCheck: ->
    twelveHours = 12 * 60 * 60
    @_lastCheckedAgo() < twelveHours

  _lastCheckedAgo: ->
    checked = parseInt(localStorage.get('updateCheckDate'))
    Date.now() - checked

  _addUpdateNotification: (detail) ->
    atom.notifications.addInfo 'Learn IDE: update available!',
      detail: detail
      description: 'Just click below to get the sweet, sweet newness.'
      dismissable: true
      buttons: [
        text: 'Install the update & restart the editor'
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

