{$, View} = require 'atom-space-pen-views'

module.exports =
class FileTreeView extends View
  @content: ->
    @div class: 'ile-file-tree tree-view-resizer tool-panel', 'data-show-on-right-side': no, =>
      @div class: 'tree-view-scroller order--center', outlet: 'scroller', =>
        @ol class: 'tree-view list-tree has-collapsable-children focusable-pane', tabindex: -1, outlet: 'list', =>
          @li class: 'directory list-nested-item project-root expanded', =>
            @div class: 'header list-item', =>
              @span class: 'name icon icon-file-directory', outlet: 'root', 'Learn.co'
      @div class: 'tree-view-resize-handle', outlet: 'resizeHandle'

  initialize: (state, fs) ->
    @panel = atom.workspace.addLeftPanel(item: this, visible: false, className: 'ile-file-tree-view')
    @handleEvents()

  handleEvents: ->
    @on 'dblclick', '.tree-view-resize-handle', =>
      @resizeToFitContent()
    @on 'mousedown', '.tree-view-resize-handle', (e) =>
      @resizeStarted(e)

  resizeStarted: =>
    $(document).on('mousemove', @resizeTreeView)
    $(document).on('mouseup', @resizeStopped)

  resizeStopped: =>
    $(document).off('mousemove', @resizeTreeView)
    $(document).off('mouseup', @resizeStopped)

  resizeTreeView: ({pageX, which}) =>
    return @resizeStopped() unless which is 1
    @width(pageX - @offset().left)

  resizeToFitContent: ->
    @width(1)
    @width(@list.outerWidth())

  toggle: ->
    if @panel.isVisible()
      @panel.hide()
    else
      @panel.show()
