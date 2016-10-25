https = require 'https'
{EventEmitter} = require 'events'
remote = require 'remote'
BrowserWindow = remote.require 'browser-window'
version = require './version'
shell = require 'shell'
path = require 'path'
localStorage = require './local-storage'

module.exports = class Updater extends EventEmitter
  constructor: (autoCheck) ->
    @currentVersion = version
    @autoCheck = autoCheck

  checkForUpdate: =>
    if (@autoCheck && @noCheckToday()) || !@autoCheck
      https.get
        host: 'api.github.com'
        path: '/repos/learn-co/learn-ide/releases/latest'
      , (response) =>
        body = ''

        response.on 'data', (d) ->
          body += d

        response.on 'end', =>
          parsed = JSON.parse(body)

          try
            current = @currentVersion.match(/[\d|\.]+/)[0]
            latest  = parsed.tag_name.match(/[\d|\.]+/)[0]

            atom.blobStore.set('learnUpdateCheckDate', 'learn-update-key', new Buffer(Date.now().toString()))
            atom.blobStore.save()

            outOfDate = current isnt latest

            if @autoCheck && !outOfDate
              console.log 'Automatically checked for updates...up to date.'
            else
              downloadUrl = @getDownloadUrl(parsed)

              localStorage.set 'updateCheck', JSON.stringify(
                downloadURL: downloadURL
                outOfDate: outOfDate
              )

              args =
                width: 500
                height: 250
                show: false
                title: 'Update Learn IDE'
                resizable: false

              win = new BrowserWindow(args)

              win.on 'closed', ->
                win = null

              updatePath = path.resolve(path.join(__dirname, '..', 'static', 'update_check.html'))

              updatePageURL = "file://#{ updatePath }"
              win.loadUrl(updatePageURL)

              win.webContents.on 'did-finish-load', ->
                win.show()

          catch err
            console.log 'There was a problem checking for updates.'
            console.error(err)

  getDownloadUrl: (githubRelease) =>
    switch process.platform
      when 'darwin'
        zip = githubRelease.assets.find (a) -> a.name.endsWith('mac.zip')
        zip.browser_download_url
      when 'win32'
        exe = githubRelease.assets.find (a) -> a.name.endsWith('.exe')
        exe.browser_download_url
      else
        githubRelease.html_url

  noCheckToday: =>
    checkDate = atom.blobStore.get('learnUpdateCheckDate', 'learn-update-key')

    if checkDate
      checkDate = parseInt(checkDate.toString())

    if !checkDate || (checkDate && ((Date.now() - checkDate) >= 86400))
      true
    else
      false
