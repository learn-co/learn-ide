fs = require 'fs'
path = require 'path'
{shell} = require 'electron'
semver = require 'semver'
{learnCo} = require './config'
fetch = require './fetch'
{install} = require './apm'
localStorage = require './local-storage'
{name} = require '../package.json'

HELP_CENTER_URL = 'https://help.learn.co/hc/en-us/sections/206572387-Common-IDE-Questions'
LATEST_VERSION_URL = "#{learnCo}/api/v1/learn_ide/latest_version"

module.exports =
  autoCheck: ->
    if not @_shouldSkipCheck()
      @_fetchLatestVersionData().then ({version, detail}) =>
        @_setCheckDate()

        if @_shouldUpdate(version)
          @_addUpdateNotification(detail)

  checkForUpdate: ->
    @_fetchLatestVersionData().then ({version, detail}) =>
      @_setCheckDate()

      if @_shouldUpdate(version)
        @_addUpdateNotification(detail)
      else
        @_addUpToDateNotification()

  update: ->
    localStorage.set('restartingForUpdate', true)
    @updateNotification?.dismiss()

    waitNotification =
      atom.notifications.addInfo 'Please wait while the update is installed...',
        description: 'This may take a few minutes. Please **do not** close the editor.'
        dismissable: true

    @_updatePackage().then (pkgResult) =>
      @_installDependencies().then (depResult) =>
        log = "Learn IDE:\n#{pkgResult.log}"
        code = pkgResult.code

        if depResult?
          log += "\nDependencies:\n#{depResult.log}"
          code += depResult.code

        if code isnt 0
          waitNotification.dismiss()
          localStorage.delete('restartingForUpdate')
          @_updateFailed(log)
          return

        localStorage.set('updateLog', log)
        atom.restartApplication()

  didRestartAfterUpdate: ->
    log = localStorage.remove('updateLog')
    target = localStorage.remove('targetedUpdateVersion')

    if @_shouldUpdate(target) then @_updateFailed(log) else @_updateSucceeded()

  _fetchLatestVersionData: ->
    fetch(LATEST_VERSION_URL).then (@latestVersionData) =>
      return @latestVersionData

  _getLatestVersion: ->
    if @latestVersionData? and @latestVersionData.version?
      return Promise.resolve(@latestVersionData.version)

    @_fetchLatestVersionData().then ({version}) ->
      return version

  _setCheckDate: ->
    localStorage.set('updateCheckDate', Date.now())

  _shouldUpdate: (latestVersion) ->
    currentVersion = require './version'

    if semver.gt(latestVersion, currentVersion)
      return true

    return @_someDependencyIsMismatched()

  _shouldSkipCheck: ->
    twelveHours = 12 * 60 * 60
    @_lastCheckedAgo() < twelveHours

  _lastCheckedAgo: ->
    checked = parseInt(localStorage.get('updateCheckDate'))
    Date.now() - checked

  _addUpdateNotification: (detail) ->
    @updateNotification =
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

  _updatePackage: ->
    @_getLatestVersion().then (version) ->
      localStorage.set('targetedUpdateVersion', version)
      install(name, version)

  _installDependencies: ->
    @_getDependenciesToInstall().then (dependencies) =>
      if not dependencies?
        return

      install(dependencies)

  _getDependenciesToInstall: ->
    @_getUpdatedDependencies().then (dependencies) =>
      packagesToUpdate = null

      for pkg, version of dependencies
        if @_shouldInstallDependency(pkg, version)
          packagesToUpdate ?= {}
          packagesToUpdate[pkg] = version

      packagesToUpdate

  _getUpdatedDependencies: ->
    @_getDependenciesFromPackagesDir().catch =>
      @_getDependenciesFromCurrentPackage()

  _getDependenciesFromPackagesDir: ->
    pkg = path.join(atom.getConfigDirPath(), 'packages', name, 'package.json')
    @_getDependenciesFromPath(pkg)

  _getDependenciesFromCurrentPackage: ->
    pkgJSON = path.resolve(__dirname, '..', 'package.json')
    @_getDependenciesFromPath(pkgJSON)

  _getDependenciesFromPath: (pkgJSON) ->
    new Promise (resolve, reject) ->
      fs.readFile pkgJSON, 'utf-8', (err, data) ->
        if err?
          reject(err)

        try
          pkg = JSON.parse(data)
        catch e
          console.error("Unable to parse #{pkgJSON}:", e)
          return reject(e)

        dependenciesObj = pkg.packageDependencies
        resolve(dependenciesObj)

  _shouldInstallDependency: (pkgName, latestVersion) ->
    pkg = atom.packages.loadPackage(pkgName)
    currentVersion = pkg?.metadata.version

    currentVersion isnt latestVersion

  _someDependencyIsMismatched: ->
    {packageDependencies} = require('../package.json')

    for pkg, version of packageDependencies
      if @_shouldInstallDependency(pkg, version)
        return true

    false

  _updateFailed: (detail) ->
    description = 'The installation seems to have been interrupted.'
    buttons = [
      {
        text: 'Retry'
        onDidClick: =>
          @update()
      }
      {
        text: 'Visit help center'
        onDidClick: ->
          shell.openExternal(HELP_CENTER_URL)
      }
    ]

    if detail?
      description = 'Please include this information when contacting the Learn support team about the issue.'
      buttons.push
        text: 'Copy this log'
        onDidClick: ->
          {clipboard} = require 'electron'
          clipboard.writeText(detail)

    @updateNotification =
      atom.notifications.addWarning('Learn IDE: update failed!', {detail, description, buttons, dismissable: true})

  _updateSucceeded: ->
    atom.notifications.addSuccess('Learn IDE: update successful!')

