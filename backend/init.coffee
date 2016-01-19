workspaceView = atom.views.getView(atom.workspace)
atom.commands.dispatch(workspaceView, 'tree-view:show')
atom.project.setPaths([atom.getUserWorkingDirPath()])
atom.commands.dispatch(workspaceView, 'integrated-learn-environment:toggleTerminal')

#   add 'mkdirp' to deps (^0.5.1)
#   Add this to src/atom-environment.coffee
#   - at top
#     mkdirp = require 'mkdirp'
#   - down near line 842ish
#     getUserWorkingDirPath: ->
#       mkdirp(@getConfigDirPath() + '/code')
#       path.join(@getConfigDirPath(), 'code')
