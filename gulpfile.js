const _ = require('underscore-plus');
const gulp = require('gulp');
const gutil = require('gulp-util');
const shell = require('shelljs');
const Client = require('ssh2').Client;
const fs = require('fs');
const os = require('os');
const path = require('path');

gulp.task('default', ['ws:start']);

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
  log('Connecting to vm02');

  var conn = new Client();
  var port = 4463
  var cmd = 'sudo su -c \"websocketd --port=' + port + ' --dir=/home/deployer/websocketd_scripts\" deployer\n'

  conn.on('ready', function() {
    log('SSH client ready...');
    log('Executing: ' + gutil.colors.yellow(cmd));

    conn.exec(cmd, function(err, stream) {
      if (err) { throw err; }

      var pids = [];
      var pidsStr = '';

      conn.exec('ps aux | grep \"websocketd --port=' + port + '\" | grep -v grep | awk \'{print $2}\'', function(err, stream) {
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
        process.stdout.write(gutil.colors.blue(data));
      }).stderr.on('data', function(data) {
        process.stderr.write(gutil.colors.red(data));
      });
    })
  }).connect({
    host: 'vm02.students.learn.co',
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
