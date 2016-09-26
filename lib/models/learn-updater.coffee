ipc = require 'ipc'
https = require 'https'
{EventEmitter} = require 'events'
remote = require 'remote'
BrowserWindow = remote.require 'browser-window'
version = require '../version'
shell = require 'shell'
path = require 'path'

module.exports = class Updater extends EventEmitter
  constructor: (autoCheck) ->
    @currentVersion = version
    @autoCheck = autoCheck

  checkForUpdate: =>
    if (@autoCheck && @noCheckToday()) || !@autoCheck
      https.get
        host: 'learn.co'
        path: '/api/v1/learn_ide/latest_version'
      , (response) =>
        body = ''

        response.on 'data', (d) ->
          body += d

        response.on 'end', =>
          parsed = JSON.parse(body)
          parsed.version = '2.0.0'

          try
            currentVersionNums = @currentVersion.split('.').map((n) -> parseInt(n))
            latestVersionNums  = parsed.version.split('.').map((n) -> parseInt(n))

            atom.blobStore.set('learnUpdateCheckDate', 'learn-update-key', new Buffer(Date.now().toString()))
            atom.blobStore.save()

            outOfDate = @outOfDate(currentVersionNums, latestVersionNums)

            if @autoCheck && !outOfDate
              console.log 'Automatically checked for updates...up to date.'
            else
              args =
                width: 500
                height: 250
                show: false
                title: 'Update Learn IDE'
                resizable: false
                outOfDate: outOfDate

              win = new BrowserWindow(args)

              win.on 'closed', ->
                win = null

              updatePlatform = if process.platform == 'win32' then 'win' else 'mac'

              updatePath = path.resolve(path.join(__dirname, '..', '..', 'static', 'update_check.html'))

              win.loadUrl("file://#{ updatePath }")

              win.webContents.on 'did-finish-load', ->
                win.show()

          catch
            console.log 'There was a problem checking for updates.'

  outOfDate: (currentNums, latestNums) =>
    @laterMajorVersion(currentNums, latestNums) || @laterMinorVersion(currentNums, latestNums) || @laterPatchVersion(currentNums, latestNums)

  laterMajorVersion: (currentNums, latestNums) =>
    latestNums[0] > currentNums[0]

  laterMinorVersion: (currentNums, latestNums) =>
    latestNums[0] == currentNums[0] && latestNums[1] > currentNums[1]

  laterPatchVersion: (currentNums, latestNums) =>
    latestNums[0] == currentNums[0] && latestNums[1] == currentNums[1] && latestNums[2] > currentNums[2]

  noCheckToday: =>
    checkDate = atom.blobStore.get('learnUpdateCheckDate', 'learn-update-key')

    if checkDate
      checkDate = parseInt(checkDate.toString())

    if !checkDate || (checkDate && Date.now() - checkDate >= 86400)
      true
    else
      false
