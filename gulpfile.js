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

gulp.task('default', ['ws:start']);

gulp.task('setup', function() {
  shell.cp('./.env.example', './.env');
});

gulp.task('download-atom', function(done) {
  var workDir = path.join(process.cwd(), 'build')
  var atomVersion = '1.10.2'
  var tarballURL = `https://github.com/atom/atom/archive/v${ atomVersion }.tar.gz`
  console.log(`Downloading Atom from ${ tarballURL }`)
  var tarballPath = path.join(workDir, 'atom.tar.gz')

  var r = request(tarballURL)

  r.on('end', function() {
    decompress(tarballPath, workDir).then(function(files) {
      fs.unlinkSync(tarballPath)
      done()
    }).catch(function(err) {
      console.error(err)
    })
  })

  r.pipe(fs.createWriteStream(tarballPath))
})

gulp.task('build', ['download-atom'], function() {
})

gulp.task('clone', function() {
  log('Cloning down all Learn IDE repositories...');
  var repos = [
    'flatiron-labs/students-chef-repo',
    'flatiron-labs/go_terminal_server',
    'flatiron-labs/fs_server',
    'flatiron-labs/learn-ide-mac-packager',
    'flatiron-labs/learn-ide-windows-packager',
    'learn-co/tree-view',
    'flatiron-labs/atom-ile'
  ];

  _.map(repos, function(repo) {
    var name = _.last(repo.split('/'));
    var cmd = 'git clone git@github.com:' + repo + '.git --progress ../' + name;
    exec(cmd, {name: name, async: true});
  })
});

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
