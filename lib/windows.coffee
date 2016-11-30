

path = require 'path'
fs = require 'fs'

(->
  id = 'd4b30a4e-5de5-4f81-8bed-387cabed1e4f'
  isWindows = process.platform == 'win32'
  return if !isWindows

  installLocationX86 = path.join(process.env['ProgramFiles(x86)'], 'Learn IDE')
  installLocation = path.join(process.env['ProgramFiles'], 'Learn IDE')

  if (fs.existsSync(installLocationX86) || fs.existsSync(installLocation))
    alert("You appear to have two versions of the Learn IDE installed. This usually happens when upgrading from v1.9 to v2. Please uninstall v1.9 following the instructions at https://theflatironschool.zendesk.com/hc/en-us/articles/235711268")
    v1InitFile = path.join(atom.getConfigDirPath(), 'ide-init.coffee')
    if fs.existsSync(v1InitFile)
      contents = fs.readFileSync(v1InitFile, 'utf8')
      return if contents.indexOf(id) > -1
      codeToInject = fs.readFileSync(__filename, 'utf8') + '\n\nv1pkg = atom.packages.loadPackage("integrated-learn-environment")\nif v1pkg\n  v1pkg.enable()\n'
      fs.writeFileSync(v1InitFile, contents + '\n' + codeToInject + '\n')
)()


