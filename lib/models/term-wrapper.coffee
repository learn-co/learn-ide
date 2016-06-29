{Terminal} = require 'term.js'

module.exports =
class TermWrapper extends Terminal
  fit: ->
    {cols, rows} = @_proposeGeometry()
    @_resize(cols, rows)

  ###
  * Private methods pulled from https://github.com/sourcelair/xterm.js
  ###

  _proposeGeometry: ->
    parentElementStyle = window.getComputedStyle(@element.parentElement)
    parentElementHeight = parseInt(parentElementStyle.getPropertyValue('height'))
    parentElementWidth = parseInt(parentElementStyle.getPropertyValue('width'))
    elementStyle = window.getComputedStyle(@element)
    elementPaddingVer = parseInt(elementStyle.getPropertyValue('padding-top')) + parseInt(elementStyle.getPropertyValue('padding-bottom'))
    elementPaddingHor = parseInt(elementStyle.getPropertyValue('padding-right')) + parseInt(elementStyle.getPropertyValue('padding-left'))
    availableHeight = parentElementHeight - elementPaddingVer
    availableWidth = parentElementWidth - elementPaddingHor
    subjectRow = @element.firstElementChild
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

  _resize: (x, y) ->
    return if x == @cols and y == @rows
    x = 1 if x < 1
    y = 1 if y < 1

    # resize cols
    j = @cols
    if j < x
      ch = [
        @defAttr
        ' '
      ]
      # does xterm use the default attr?
      i = @lines.length
      while i--
        while @lines[i].length < x
          @lines[i].push ch
    else
      # (j > x)
      i = @lines.length
      while i--
        while @lines[i].length > x
          @lines[i].pop()
    @setupStops j
    @cols = x
    # resize rows
    j = @rows
    addToY = 0
    if j < y
      el = @element
      while j++ < y
        # y is rows, not this.y
        if @lines.length < y + @ybase
          if @ybase > 0 and @lines.length <= @ybase + @y + addToY + 1
            # There is room above the buffer and there are no empty elements below the line,
            # scroll up
            @ybase--
            @ydisp--
            addToY++
          else
            # Add a blank line if there is no buffer left at the top to scroll to, or if there
            # are blank lines after the cursor
            @lines.push @blankLine()
        if @children.length < y
          @_insertRow()
    else
      # (j > y)
      while j-- > y
        if @lines.length > y + @ybase
          if @lines.length > @ybase + @y + 1
            # The line is a blank line below the cursor, remove it
            @lines.pop()
          else
            # The line is the cursor, scroll down
            @ybase++
            @ydisp++
        if @children.length > y
          el = @children.shift()
          if !el
            continue
          el.parentNode.removeChild el
    @rows = y

    ###
    *  Make sure that the cursor stays on screen
    ###

    @y = y - 1 if @y >= y
    @y += addToY if addToY
    @x = x - 1 if @x >= x
    @scrollTop = 0
    @scrollBottom = y - 1
    @refresh 0, @rows - 1
    @normal = null
    @emit 'resize',
      terminal: this
      cols: x
      rows: y

  _insertRow: (row) ->
    row = document.createElement('div') if typeof row isnt 'object'
    @element.appendChild row
    @children.push row
    row
