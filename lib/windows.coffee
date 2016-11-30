

(->
  'wutang'
  isWindows = process.platform == 'win32'
  return if !isWindows

  installLocationX86 = path.join(process.env['ProgramFiles(x86)'], 'Learn IDE')
  installLocation = path.join(process.env['ProgramFiles'], 'Learn IDE')

  if (fs.existsSync(installLocationX86) || fs.existsSync(installLocation))
    v1InitFile = path.join(atom.getConfigDirPath(), 'ide-init.coffee')
    if fs.existsSync(v1InitFile)
      contents = fs.readFileSync(v1InitFile, 'utf8')
      codeToInject = fs.readFileSync(__filename, 'utf8')
      fs.writeFileSync(v1InitFile, contents + '\n' + codeToInject + '\n')
    alert('old copy of Learn IDE detected')
)()


