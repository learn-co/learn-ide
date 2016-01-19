workspaceView = atom.views.getView(atom.workspace)
atom.commands.dispatch(workspaceView, 'tree-view:show')
atom.project.setPaths([atom.getUserWorkingDirPath()])
atom.commands.dispatch(workspaceView, 'integrated-learn-environment:toggleTerminal')
