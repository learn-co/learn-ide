{BufferedProcess} = require 'atom'
command = atom.packages.getApmPath()

run = (args) ->
  new Promise (resolve) ->
    log = ''

    stdout = (data) ->
      log += "  #{data}"

    exit = (code) ->
      resolve({log, code})

    new BufferedProcess({command, args, stdout, exit})

fullname = (name, version) ->
  if version? then "#{name}@#{version}" else name

parseNameAndVersionObject = (namesAndVersions) ->
  fullnames = []

  for name, version of namesAndVersions
    fullnames.push(fullname(name, version))

  fullnames

module.exports = apm =
  install: (name, version) ->
    args =
      if typeof name is 'object'
        parseNameAndVersionObject(name)
      else
        [fullname(name, version)]

    run(['install', '--compatible', '--no-confirm', '--no-color'].concat(args))


