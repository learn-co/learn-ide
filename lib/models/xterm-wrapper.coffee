Xterm = require 'xterm'

# TODO: Get the xterm/addons/fit module to work and remove this class entirely.
#       It is only a wrapper that manually brings in the `fit` addon.

module.exports =
class XtermWrapper extends Xterm
  proposeGeometry: ->
    parentElementStyle = window.getComputedStyle(@element.parentElement)
    parentElementHeight = parseInt(parentElementStyle.getPropertyValue('height'))
    parentElementWidth = parseInt(parentElementStyle.getPropertyValue('width'))
    elementStyle = window.getComputedStyle(@element)
    elementPaddingVer = parseInt(elementStyle.getPropertyValue('padding-top')) + parseInt(elementStyle.getPropertyValue('padding-bottom'))
    elementPaddingHor = parseInt(elementStyle.getPropertyValue('padding-right')) + parseInt(elementStyle.getPropertyValue('padding-left'))
    availableHeight = parentElementHeight - elementPaddingVer
    availableWidth = parentElementWidth - elementPaddingHor
    container = @rowContainer
    subjectRow = @rowContainer.firstElementChild
    contentBuffer = subjectRow.innerHTML

    subjectRow.style.display = 'inline'
    subjectRow.innerHTML = 'W' # Common character for measuring width although on monospace
    characterWidth = subjectRow.getBoundingClientRect().width
    subjectRow.style.display = '' # Revert style before calculating height, since they differ.
    characterHeight = parseInt(subjectRow.offsetHeight)
    subjectRow.innerHTML = contentBuffer

    rows = parseInt(availableHeight / characterHeight)
    cols = parseInt(availableWidth / characterWidth) - 1

    {cols, rows}

  fit: ->
    {cols, rows} = @proposeGeometry()
    @resize(cols, rows)
