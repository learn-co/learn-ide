{shell} = require 'electron'
{BufferedProcess} = require 'atom'
compare = require 'semver-compare'
{learnCo} = require './config'
fetch = require './fetch'
localStorage = require './local-storage'

HELP_CENTER_URL = 'https://help.learn.co/hc/en-us/sections/206572387-Common-IDE-Questions'
LATEST_VERSION_URL = "#{learnCo}/api/v1/learn_ide/latest_version"

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
        text: 'Install update & restart editor'
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
    atom.notifications.addWarning 'Learn IDE: update failed!',
      detail: log
      description: 'Please include this information when contacting the Learn support team about the issue.'
      dismissable: true
      buttons: [
        {
          text: 'Copy this log'
          onDidClick: ->
            {clipboard} = require 'electron'
            clipboard.writeText(log)
        }
        {
          text: 'Visit the help center'
          onDidClick: ->
            shell.openExternal(HELP_CENTER_URL)
        }
      ]

  _updateSucceeded: (log) ->
    atom.notifications.addSuccess 'Learn IDE: update successful!',
      detail: log

