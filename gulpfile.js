require('dotenv').config({silent: true});
const _ = require('underscore-plus');
const gulp = require('gulp');
const gutil = require('gulp-util');
const shell = require('shelljs');
const Client = require('ssh2').Client;
const fs = require('fs');
const os = require('os');
const path = require('path');
const decompress = require('decompress');
const request = require('request');
const del = require('del');
const runSequence = require('run-sequence');
const cp = require('./utils/child-process-wrapper');
const pkg = require('./package.json')

var buildBeta;

var buildDir = path.join(__dirname, 'build')
console.log('build directory', buildDir)

function productName() {
  var name = 'Learn IDE';

  if (buildBeta) {
    name += ' Beta';
  }

  return name;
}

function executableName() {
  var name = productName().toLowerCase();
  return name.replace(/ /g, '_');
}

function windowsInstallerName() {
  return productName().replace(/ /g, '') + 'Setup.exe';
}

gulp.task('default', ['ws:start']);

gulp.task('setup', function() {
  shell.cp('./.env.example', './.env');
});

gulp.task('download-atom', function(done) {
  var tarballURL = `https://github.com/atom/atom/archive/v${ pkg.atomVersion }.tar.gz`
  console.log(`Downloading Atom from ${ tarballURL }`)
  var tarballPath = path.join(buildDir, 'atom.tar.gz')

  var r = request(tarballURL)

  r.on('end', function() {
    decompress(tarballPath, buildDir, {strip: 1}).then(function(files) {
      fs.unlinkSync(tarballPath)
      done()
    }).catch(function(err) {
      console.error(err)
    })
  })

  r.pipe(fs.createWriteStream(tarballPath))
})

gulp.task('build-atom', function(done) {
  process.chdir(buildDir)

  var cmd  = path.join(buildDir, 'script', 'build')
  var args = []

  switch (process.platform) {
    case 'win32':
      args.push('--create-windows-installer');
      break;

    case 'darwin':
      args.push('--compress-artifacts');
      args.push('--code-sign');
      break;

    case 'linux':
      args.push('--create-rpm-package');
      args.push('--create-debian-package');
      break;
  }

  if (process.platform == 'win32') {
    args = ['/s', '/c', cmd].concat(args);
    cmd = 'cmd';
  }

  console.log('running command: ' + cmd + ' ' + args.join(' '))
  cp.safeSpawn(cmd, args, function() {
    done()
  })
})

gulp.task('reset', function() {
  del.sync(['build/**/*', '!build/.gitkeep'], {dot: true})
})

gulp.task('sleep', function(done) {
  setTimeout(function() { done() }, 1000 * 60)
})

gulp.task('inject-packages', function() {
  function rmPackage(name) {
    var packageJSON = path.join(buildDir, 'package.json')
    var packages = JSON.parse(fs.readFileSync(packageJSON))
    delete packages.packageDependencies[name]
    fs.writeFileSync(packageJSON, JSON.stringify(packages, null, '  '))
  }

  function injectPackage(name, version) {
    var packageJSON = path.join(buildDir, 'package.json')
    var packages = JSON.parse(fs.readFileSync(packageJSON))
    packages.packageDependencies[name] = version
    fs.writeFileSync(packageJSON, JSON.stringify(packages, null, '  '))
  }

  var pkg = require('./package.json')
  rmPackage('welcome')
  rmPackage('tree-view')
  injectPackage('learn-ide', pkg.version)
  injectPackage('learn-ide-tree', pkg.treeVersion)
})

gulp.task('replace-files', function() {
  var iconSrc = path.join('resources', 'app-icons', '**', '*');
  var iconDest = path.join(buildDir, 'resources', 'app-icons', 'stable')

  gulp.src([iconSrc]).pipe(gulp.dest(iconDest));

  var winSrc = path.join('resources', 'win', '**', '*');
  var winDest = path.join(buildDir, 'resources', 'win');

  gulp.src([winSrc]).pipe(gulp.dest(winDest));

  var scriptSrc = path.join('resources', 'script-replacements', '**', '*');
  var scriptDest = path.join(buildDir, 'script', 'lib')

  gulp.src([scriptSrc]).pipe(gulp.dest(scriptDest));
})

gulp.task('alter-files', function() {
  function replaceInFile(filepath, replaceArgs) {
    var data = fs.readFileSync(filepath, 'utf8');

    replaceArgs.forEach(function(args) {
      data = data.replace(args[0], args[1]);
    });

    fs.writeFileSync(filepath, data)
  }

  replaceInFile(path.join(buildDir, 'script', 'lib', 'create-windows-installer.js'), [
    [
      'https://raw.githubusercontent.com/atom/atom/master/resources/app-icons/${CONFIG.channel}/atom.ico',
      'https://raw.githubusercontent.com/learn-co/learn-ide/master/resources/app-icons/atom.ico'
    ]
  ])

  replaceInFile(path.join(buildDir, 'script', 'lib', 'create-rpm-package.js'), [
    ['atom.${generatedArch}.rpm', executableName() + '.${generatedArch}.rpm'],
    [/'Atom Beta' : 'Atom'/g, "'" + productName() + "' : '" + productName() + "'"]
  ]);

  replaceInFile(path.join(buildDir, 'script', 'lib', 'create-debian-package.js'), [
    ['atom-${arch}.deb', executableName() + '-${arch}.deb'],
    [/'Atom Beta' : 'Atom'/g, "'" + productName() + "' : '" + productName() + "'"]
  ]);

  replaceInFile(path.join(buildDir, 'script', 'lib', 'package-application.js'), [
    [/'Atom Beta' : 'Atom'/g, "'" + productName() + "' : '" + productName() + "'"]
  ]);

  replaceInFile(path.join(buildDir, 'script', 'lib', 'package-application.js'), [
    [/'Atom'/g, `'${productName()}'`]
  ]);

  if (process.platform != 'linux') {
    replaceInFile(path.join(buildDir, 'script', 'lib', 'package-application.js'), [
      [/return 'atom'/, "return '" + executableName() + "'"],
      [/'atom-beta' : 'atom'/g, "'" + executableName() + "' : '" + executableName() + "'"]
    ]);
  }

  replaceInFile(path.join(buildDir, 'script', 'lib', 'compress-artifacts.js'), [
    [/atom-/g, executableName() + '-']
  ]);

  replaceInFile(path.join(buildDir, 'src', 'main-process', 'atom-application.coffee'), [
    [
      'options.socketPath = "\\\\.\\pipe\\atom-#{options.version}-#{userNameSafe}-sock"',
      'options.socketPath = "\\\\.\\pipe\\' + executableName() + '-#{options.version}-#{userNameSafe}-sock"',
    ],
    [
      'options.socketPath = path.join(os.tmpdir(), "atom-#{options.version}-#{process.env.USER}.sock")',
      'options.socketPath = path.join(os.tmpdir(), "' + executableName() + '-#{options.version}-#{process.env.USER}.sock")'
    ]
  ]);

  replaceInFile(path.join(buildDir, 'resources', 'mac', 'atom-Info.plist'), [
    [
      /(CFBundleURLSchemes.+\n.+\n.+)(atom)(.+)/,
      '$1learn-ide$3'
    ]
  ]);

  replaceInFile(path.join(buildDir, 'src', 'main-process', 'atom-protocol-handler.coffee'), [
    [
      /(registerFileProtocol.+)(atom)(.+)/,
      '$1learn-ide$3'
    ]
  ]);

  replaceInFile(path.join(buildDir, 'src', 'main-process', 'parse-command-line.js'), [
    [
      /(urlsToOpen.+)/,
      "$1\n  if (args['url-to-open']) { urlsToOpen.push(args['url-to-open']) }\n"
    ],
    [
      /(const args)/,
      "options.string('url-to-open')\n  $1"
    ]
  ]);
})

gulp.task('update-package-json', function() {
  var packageJSON = path.join(buildDir, 'package.json')
  var atomPkg = JSON.parse(fs.readFileSync(packageJSON))
  var learnPkg = require('./package.json')

  atomPkg.name = executableName()
  atomPkg.productName = productName()
  atomPkg.version = learnPkg.version
  atomPkg.description = learnPkg.description

  fs.writeFileSync(packageJSON, JSON.stringify(atomPkg, null, '  '))
})

gulp.task('rename-installer', function(done) {
  var src = path.join(buildDir, 'out', productName() + 'Setup.exe');
  var des = path.join(buildDir, 'out', windowsInstallerName());

  fs.rename(src, des, function (err) {
    if (err) {
      console.log('error while renaming: ', err.message)
    }

    done()
  })
})

gulp.task('sign-installer', function() {
  var certPath = process.env.FLATIRON_P12KEY_PATH;
  var password = process.env.FLATIRON_P12KEY_PASSWORD;

  if (!certPath || !password) {
    console.log('unable to sign installer, must provide FLATIRON_P12KEY_PATH and FLATIRON_P12KEY_PASSWORD environment variables')
    return
  }

  var cmd = path.join(buildDir, 'script', 'node_modules', 'electron-winstaller', 'vendor', 'signtool.exe')
  var installer = path.join(buildDir, 'out', windowsInstallerName());
  args = ['sign', '/a', '/f', certPath, '/p', "'" + password + "'", installer]

  console.log('running command: ' + cmd + ' ' + args.join(' '))
  cp.safeSpawn(cmd, args, function() {
    done()
  })
})

gulp.task('cleanup', function(done) {
  switch (process.platform) {
    case 'win32':
      runSequence('rename-installer', 'sign-installer', done)
      break;

    case 'darwin':
      done()
      break;

    case 'linux':
      done()
      break;
  }
})

gulp.task('prep-build', function(done) {
  runSequence(
    'inject-packages',
    'replace-files',
    'alter-files',
    'update-package-json',
    done
  )
})

gulp.task('build', function(done) {
  var pkg = require('./package.json')
  if (pkg.version.match(/beta/)) { buildBeta = true }

  runSequence(
    'reset',
    'download-atom',
    'prep-build',
    'build-atom',
    'cleanup',
    done
  )
})

