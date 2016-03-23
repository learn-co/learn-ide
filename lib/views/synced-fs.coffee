{$, View}  = require 'atom-space-pen-views'
file_sys   = require 'fs'
mkdirp     = require 'mkdirp'
execSync   = require('child_process').execSync
spawn      = require('child_process').spawnSync
crossSpawn = require('cross-spawn').spawn
rmdir      = require 'rimraf'
utf8       = require 'utf8'
ipc        = require 'ipc'

module.exports =
class TerminalView extends View
  @content: ->
    @div class: 'learn-synced-fs-status inline-block icon-terminal'

  constructor: (state, fs) ->
    super

    @fs = fs
    ipc.send 'fs-connection-state-request'

    # Default text
    @text(" Learn")
    @element.style.color = '#d92626'

    @handleEvents()

  handleEvents: ->
    ipc.on 'fs-connection-state', (state) =>
      if state == 'open'
        @element.style.color = '#73c990'
      else
        @element.style.color = '#d92626'
