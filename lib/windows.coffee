

(->
  path = require 'path'
  fs = require 'fs'
  shell = require 'shell'

  id = 'd4b30a4e-5de5-4f81-8bed-387cabed1e4f'
  isWindows = process.platform == 'win32'
  return if !isWindows

  installLocationX86 = path.join((process.env['ProgramFiles(x86)'] || ''), 'Learn IDE')
  installLocation = path.join((process.env['ProgramFiles'] || ''), 'Learn IDE')

  if (fs.existsSync(installLocationX86) || fs.existsSync(installLocation))
    alert("You appear to have two versions of the Learn IDE installed. This happens when upgrading from v1.9 to v2 on Windows. Please uninstall v1.9 by following the instructions in the help article that opens when you close this alert.")
    shell.openExternal('https://theflatironschool.zendesk.com/hc/en-us/articles/235711268')

    v1InitFile = path.join((atom.getConfigDirPath() || ''), 'ide-init.coffee')
    if fs.existsSync(v1InitFile)
      contents = fs.readFileSync(v1InitFile, 'utf8')
      return if contents.indexOf(id) > -1
      codeToInject = fs.readFileSync(path.join(__dirname, 'windows_code.txt'), 'utf8') + '\n\nv1pkg = atom.packages.loadPackage("integrated-learn-environment")\nif v1pkg\n  v1pkg.enable()\n'
      fs.writeFileSync(v1InitFile, contents + '\n' + codeToInject + '\n')
)()


