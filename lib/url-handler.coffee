#ipc = require 'ipc'

#ipc.send 'user-opened-file'
#{urlToOpen} = JSON.parse(decodeURIComponent(location.search.substr(14)))

#console.log urlToOpen

#ipc = require 'ipc'
#ipc.send('call-window-method', 'show')
#ipc.send('call-window-method', 'focus')
#window.focus()

#ipc.send('call-window-method', 'openDevTools')

#url = require 'url'

#parsed = url.parse urlToOpen, true
#console.log parsed

#filePath = "/Users/tclem/github/github/#{parsed.query.filepath}"
#console.log filePath

# TODO Once you have the path to open, uncomment this line
#ipc.send('open', {pathsToOpen: ['/Users/loganhasson/Desktop/ile_opeh.html']})

# TODO Once done, uncomment this to close the window
# require('remote').getCurrentWindow().close()
module.exports =
  activate: (state) ->
    console.log('here')
