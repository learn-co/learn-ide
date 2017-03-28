fs = require 'fs'
path = require 'path'
atomHelper = require './atom-helper'
{name} = require '../package.json'

STYLESHEET_PATH = path.join(__dirname, '..', 'styles', 'terminal-colors.css')

helper =
  convertLegacyConfig: ->
    text = atom.config.get("#{name}.terminalFontColor")
    atom.config.unset("#{name}.terminalFontColor")
    if text?
      atom.config.set("#{name}.terminalColors.basic.foreground", text)

    background = atom.config.get("#{name}.terminalBackgroundColor")
    atom.config.unset("#{name}.terminalBackgroundColor")
    if background?
      atom.config.set("#{name}.terminalColors.basic.background", background)

  ansiObjectToArray: (ansiColorsObject) ->
    colorArray = []

    for indexish, color of ansiColorsObject
      index = parseInt(indexish)
      colorArray[index] = color.toRGBAString()

    colorArray

  ansiArrayToObject: (ansiColorsArray) ->
    colorObject = {}

    ansiColorsArray.forEach (color, index) ->
      colorObject[index] = color

    colorObject

  buildCSS: ({foreground, background, ansiColors}) ->
    css = """
      .terminal {
        color: #{foreground.toRGBAString()};
      }

      .terminal .xterm-viewport {
        background-color: #{background.toRGBAString()};
      }\n
      """

    ansiColors.forEach (color, index) ->
      css += """
        \n.terminal .xterm-color-#{index} {
          color: #{color};
        }

        .terminal .xterm-bg-color-#{index} {
          background-color: #{color};
        }\n
        """

    return css

  addStylesheet: (css) ->
    new Promise (resolve, reject) ->
      fs.writeFile STYLESHEET_PATH, css, (err) ->
        if err?
          console.warn 'unable to write colors to file:', err
          atomHelper.addStylesheet(css)
        resolve()

module.exports = colors =
  apply: ->
    console.debug('APPLY')
    helper.convertLegacyConfig()

    foreground = atom.config.get("#{name}.terminalColors.basic.foreground")
    background = atom.config.get("#{name}.terminalColors.basic.background")
    ansiColors = helper.ansiObjectToArray(atom.config.get("#{name}.terminalColors.ansi"))

    css = helper.buildCSS({foreground, background, ansiColors})

    helper.addStylesheet(css).then ->
      atomHelper.reloadStylesheets()

  parseJSON: (jsonString) ->
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
      return

    ansiColorsObject = helper.ansiArrayToObject(color)

    atom.config.set("#{name}.terminalColors.ansi", ansiColorsObject)
    atom.config.set("#{name}.terminalColors.basic", {foreground, background})

