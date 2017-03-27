fs = require 'fs'
path = require 'path'
atomHelper = require './atom-helper'
{name} = require '../package.json'

module.exports = setTerminalColors = ->
  # TODO: handle legacy config keys
  text = atom.config.get("#{name}.basicColors.text")
  background = atom.config.get("#{name}.basicColors.background")

  css = """
    .terminal {
      color: #{text.toRGBAString()};
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

