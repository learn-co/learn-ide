'use babel'

import {BufferedProcess} from 'atom';

function run(args) {
  return new Promise(function(resolve) {
    var command = atom.packages.getApmPath();

    var log = '';
    var stdout = data => log += `${data}`;
    var stderr = data => log += `${data}`;

    var exit = code => resolve({log, code});

    new BufferedProcess({command, args, stdout, stderr, exit});
  });
}

function fullname(name, version) {
  return (version != null) ? `${name}@${version}` : name
};

function parseDependencies(dependencies) {
  return Object.keys(dependencies).map((name) => {
    return fullname(name, dependencies[name])
  })
};

export default {
  install(name, version) {
    var nameIsObject = typeof name === 'object';

    var args = nameIsObject ? parseDependencies(name) : [fullname(name, version)];

    return run(['install', '--compatible', '--no-confirm', '--no-color'].concat(args));
  }
}
