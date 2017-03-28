fs = require 'fs'
path = require 'path'
atomHelper = require './atom-helper'
{name} = require '../package.json'

convertLegacyConfig = ->
  text = atom.config.get("#{name}.terminalFontColor")
  atom.config.unset("#{name}.terminalFontColor")
  if text?
    atom.config.set("#{name}.basicColors.text", text)

  background = atom.config.get("#{name}.terminalBackgroundColor")
  atom.config.unset("#{name}.terminalBackgroundColor")
  if background?
    atom.config.set("#{name}.basicColors.background", background)

module.exports = colors =
  parseTerminalDotSexyScheme: (jsonString) ->
    if not jsonString? or not jsonString.length
      return

    try
      scheme = JSON.parse(jsonString)
    catch err
      console.error err
      atom.notifications.addWarning 'Learn IDE: Unable to parse color scheme!',
        description: 'The scheme you\'ve entered is invalid JSON. Did you export the complete JSON from [terminal.sexy](https://terminal.sexy)?'
      return

    {color, foreground, background} = scheme

    if not color? or not foreground? or not background?
      atom.notifications.addWarning 'Learn IDE: Unable to parse color scheme!',
        description: 'The scheme you\'ve entered is incomplete. Be sure to export the complete JSON from [terminal.sexy](https://terminal.sexy)?'

    ansiColors = {}
    color.forEach (value, index) ->
      ansiColors["ansiColor#{index}"] = value

    atom.config.set("#{name}.ansiColors", ansiColors)
    atom.config.set("#{name}.basicColors", {foreground, background})

  updateTerminal: ->
    convertLegacyConfig()
    foreground = atom.config.get("#{name}.basicColors.foreground")
    background = atom.config.get("#{name}.basicColors.background")

    css = """
      .terminal {
        color: #{foreground.toRGBAString()};
      }

      .terminal .xterm-viewport {
        background-color: #{background.toRGBAString()};
      }\n
      """

    for n in [0..15]
      color = atom.config.get("#{name}.ansiColors.ansiColor#{n}")
      rgba = color.toRGBAString()

      css += """
        \n.terminal .xterm-color-#{n} {
          color: #{rgba};
        }

        .terminal .xterm-bg-color-#{n} {
          background-color: #{rgba};
        }\n
        """

    file = path.join(__dirname, '..', 'styles', 'terminal-colors.css')
    fs.writeFile file, css, (err) ->
      if err?
        console.warn 'unable to write colors to file:', err
        atomHelper.addStylesheet(css)

      atomHelper.reloadStylesheets()

