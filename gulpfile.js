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

var buildDir = path.join(__dirname, 'build')
console.log('build directory', buildDir)

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

  var cmd  = process.platform === 'win32' ? 'script\\build' : 'script/build'
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

  rmPackage('tree-view')
  injectPackage('mastermind', '0.0.5')
  injectPackage('learn-ide-tree', '1.0.1')
})

gulp.task('replace-app-icons', function() {
  var iconSrc = path.join('resources', 'app-icons', '**', '*');
  var iconDest = path.join(buildDir, 'resources', 'app-icons', 'stable')

  gulp.src([iconSrc]).pipe(gulp.dest(iconDest));

  var loadingSrc = path.join('resources', 'win', '**', '*');
  var loadingDest = path.join(buildDir, 'resources', 'win');

  gulp.src([loadingSrc]).pipe(gulp.dest(loadingDest));
})

gulp.task('replace-code-sign', function() {
  var src = 'resources/code-sign-on-mac.js';
  var dest = path.join(buildDir, 'script', 'lib')

  gulp.src([src]).pipe(gulp.dest(dest));
})

gulp.task('rename-app', function() {
  function replaceInFile(filepath, replaceArgs) {
    var data = fs.readFileSync(filepath, 'utf8');

    replaceArgs.forEach(function(args) {
      data = data.replace(args[0], args[1]);
    });

    fs.writeFileSync(filepath, data)
  }

  var packageApplication = path.join(buildDir, 'script', 'lib', 'package-application.js');
  var pkgAppReplacements = [ [/'Atom Beta' : 'Atom'/g, "'Atom Beta' : 'Learn IDE'"] ];

  if (process.platform == 'win32') {
    pkgAppReplacements.push(
      [/return 'atom'/, "return 'learnide'"],
      [/'atom-beta' : 'atom'/g, "'atom-beta' : 'learnide'"]
    );
  } else {
    pkgAppReplacements.push(
      [/return 'atom'/, "return 'learn-ide'"],
      [/'atom-beta' : 'atom'/g, "'atom-beta' : 'learn-ide'"]
    );
  }

  replaceInFile(packageApplication, pkgAppReplacements);

  replaceInFile(path.join(buildDir, 'script', 'lib', 'compress-artifacts.js'), [
    [/atom-/g, 'learn-ide-']
  ]);

  replaceInFile(path.join(buildDir, 'src', 'main-process', 'atom-application.coffee'), [
    [
      'options.socketPath = "\\\\.\\pipe\\atom-#{options.version}-#{userNameSafe}-sock"',
      'options.socketPath = "\\\\.\\pipe\\learn-ide-#{options.version}-#{userNameSafe}-sock"',
    ],
    [
      'options.socketPath = path.join(os.tmpdir(), "atom-#{options.version}-#{process.env.USER}.sock")',
      'options.socketPath = path.join(os.tmpdir(), "learn-ide-#{options.version}-#{process.env.USER}.sock")'
    ]
  ]);
})

gulp.task('update-package-json', function() {
  var packageJSON = path.join(buildDir, 'package.json')
  var atomPkg = JSON.parse(fs.readFileSync(packageJSON))
  var learnPkg = require('./package.json')

  atomPkg.name = process.platform == 'win32' ? 'learnide' : 'learn-ide'
  atomPkg.productName = 'Learn IDE'
  atomPkg.version = learnPkg.version
  atomPkg.description = learnPkg.description

  fs.writeFileSync(packageJSON, JSON.stringify(atomPkg, null, '  '))
})

gulp.task('build', function(done) {
  runSequence(
    'reset',
    'download-atom',
    'prep-build',
    'build-atom',
    done
  )
})

gulp.task('prep-build', function(done) {
  runSequence(
    'inject-packages',
    'replace-app-icons',
    'replace-code-sign',
    'rename-app',
    'update-package-json',
    done
  )
})

gulp.task('ws:start', function(done) {
  var conn = new Client();
  var host = process.env.IDE_WS_HOST || 'vm02.students.learn.co';
  var port = process.env.IDE_WS_PORT || 1337;
  var cmd = 'sudo su -c \"websocketd --port=' + port + ' --dir=/home/deployer/websocketd_scripts\" deployer\n'

  log('Connecting to ' + host + ' on port ' + port);

  conn.on('ready', function() {
    log('SSH client ready...');
    log('Executing ' + gutil.colors.yellow(cmd.replace('\n', '')) + ' on ' + gutil.colors.magenta(host));

    conn.exec(cmd, function(err, stream) {
      if (err) { throw err; }

      var pids = [];
      var pidsStr = '';

      conn.exec('ps aux | grep \"websocketd --port=' + port + '\" | grep -v grep | awk \'{print $2}\'', function(err, stream) {
        if (err) { throw err }
        stream.on('data', function(data) {
          pids = _.compact(data.toString().split('\n'))
          pidsStr = pids.join(' ')
          log('WebsocketD processes started with pids: ' + pidsStr);
        });
      })

      process.on('SIGINT', function() {
        log('Killing websocket processes ' + pidsStr);
        conn.exec('sudo kill ' + pidsStr, function(err, stream) {
          stream.on('close', function() {
            process.exit(0);
          });
        });
      });

      stream.on('close', function(code) {
        gutil.log('SSH stream closed with code ' + code);
        conn.end();
      }).on('data', function(data) {
        process.stdout.write('[' + gutil.colors.magenta(host) + '] ' + gutil.colors.blue(data));
      }).stderr.on('data', function(data) {
        process.stderr.write('[' + gutil.colors.magenta(host) + '] ' + gutil.colors.red(data));
      });
    })
  }).connect({
    host: host,
    username: process.env['USER'],
    agent: process.env.SSH_AUTH_SOCK
  });
});

function log (msg) {
  gutil.log(gutil.colors.green(msg));
}

function exec (cmd, opts, cb) {
  opts || (opts = {});

  _.defaults(opts, {
    name: cmd,
    async: false
  });

  gutil.log(gutil.colors.green('Executing ') + gutil.colors.yellow(cmd));

  var child = shell.exec(cmd, {async: opts.async}, cb);

  if (opts.async) {
    child.stdout.on('data', function(data) {
      process.stdout.write(gutil.colors.green(opts.name + ': ') + data);
    });

    child.stderr.on('data', function(data) {
      process.stderr.write(gutil.colors.green(opts.name + ': ') + data);
    });
  }
}
