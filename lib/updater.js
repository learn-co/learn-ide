'use babel'

import fetch from './fetch'
import fs from 'fs'
import localStorage from './local-storage'
import path from 'path'
import semver from 'semver'
import {install} from './apm'
import {learnCo} from './config'
import {name} from '../package.json'

var helpCenterUrl = `${learnCo}/ide/faq`;

var latestVersionUrl = (function() {
  var {version} = require('../package.json');
  var isBeta = version.includes('beta');
  return isBeta ? `${learnCo}/api/v1/learn_ide/latest_beta_version` : `${learnCo}/api/v1/learn_ide/latest_version`
})()

export default {
  autoCheck() {
    if (this._shouldSkipCheck()) { return }

    this._fetchLatestVersionData().then(({version, detail}) => {
      this._setCheckDate();

      if (this._shouldUpdate(version)) { this._addUpdateNotification(detail) }
    });
  },

  checkForUpdate() {
    this._fetchLatestVersionData().then(({version, detail}) => {
      this._setCheckDate();

      if (this._shouldUpdate(version)) {
        this._addUpdateNotification(detail);
      } else {
        this._addUpToDateNotification();
      }
    });
  },

  update() {
    localStorage.set('restartingForUpdate', true);

    if (this.updateNotification != null) {
      this.updateNotification.dismiss();
    }

    var waitNotification =
      atom.notifications.addInfo('Please wait while the update is installed...', {
        description: 'This may take a few minutes. Please **do not** close the editor.',
        dismissable: true
      });

    this._updatePackage().then(pkgResult => {
      this._installDependencies().then(depResult => {
        var log = `Learn IDE:\n---\n${pkgResult.log}`;
        var { code } = pkgResult;

        if (depResult != null) {
          log += `\nDependencies:\n---\n${depResult.log}`;
          code += depResult.code;
        }

        if (code !== 0) {
          waitNotification.dismiss();
          localStorage.delete('restartingForUpdate');
          this._updateFailed(log);
          return;
        }

        localStorage.set('updateLog', log);
        atom.restartApplication();
      });
    });
  },

  didRestartAfterUpdate() {
    var log = localStorage.remove('updateLog');
    var target = localStorage.remove('targetedUpdateVersion');

    this._shouldUpdate(target) ? this._updateFailed(log) : this._updateSucceeded()
  },

  _fetchLatestVersionData() {
    return fetch(latestVersionUrl).then(latestVersionData => {
      this.latestVersionData = latestVersionData;
      return this.latestVersionData;
    });
  },

  _getLatestVersion() {
    if ((this.latestVersionData != null) && (this.latestVersionData.version != null)) {
      return Promise.resolve(this.latestVersionData.version);
    }

    return this._fetchLatestVersionData().then(({version}) => version);
  },

  _setCheckDate() {
    localStorage.set('updateCheckDate', Date.now());
  },

  _shouldUpdate(latestVersion) {
    var {version} = require('../package.json');

    if (semver.gt(latestVersion, version)) {
      return true;
    }

    return this._someDependencyIsMismatched();
  },

  _shouldSkipCheck() {
    var twelveHours = 12 * 60 * 60;
    return this._lastCheckedAgo() < twelveHours;
  },

  _lastCheckedAgo() {
    var checked = parseInt(localStorage.get('updateCheckDate'));
    return Date.now() - checked;
  },

  _addUpdateNotification(detail) {
    this.updateNotification =
      atom.notifications.addInfo('Learn IDE: update available!', {
        detail,
        description: 'Just click below to get the sweet, sweet newness.',
        dismissable: true,
        buttons: [{
          text: 'Install update & restart editor',
          onDidClick: () => this.update()
        }]
      });
  },

  _addUpToDateNotification() {
    atom.notifications.addSuccess('Learn IDE: up-to-date!');
  },

  _updatePackage() {
    return this._getLatestVersion().then(version => {
      localStorage.set('targetedUpdateVersion', version);
      return install(name, version);
    });
  },

  _installDependencies() {
    return this._getDependenciesToInstall().then(dependencies => {
      if (dependencies == null) { return }
      if (Object.keys(dependencies).length <= 0) { return }

      return install(dependencies);
    });
  },

  _getDependenciesToInstall() {
    return this._getUpdatedDependencies().then(dependencies => {
      var packagesToUpdate = {};

      Object.keys(dependencies).forEach(pkg => {
        var version = dependencies[pkg];
        if (this._shouldInstallDependency(pkg, version)) {
          packagesToUpdate[pkg] = version;
        }
      })

      return packagesToUpdate;
    });
  },

  _getUpdatedDependencies() {
    return this._getDependenciesFromPackagesDir().catch(() => {
      return this._getDependenciesFromCurrentPackage();
    });
  },

  _getDependenciesFromPackagesDir() {
    var pkg = path.join(atom.getConfigDirPath(), 'packages', name, 'package.json');
    return this._getDependenciesFromPath(pkg);
  },

  _getDependenciesFromCurrentPackage() {
    var pkgJSON = path.resolve(__dirname, '..', 'package.json');
    return this._getDependenciesFromPath(pkgJSON);
  },

  _getDependenciesFromPath(pkgJSON) {
    return new Promise((resolve, reject) => {
      fs.readFile(pkgJSON, 'utf-8', (err, data) => {
        if (err != null) {
          reject(err)
          return
        }

        try {
          var pkg = JSON.parse(data);
        } catch (e) {
          console.error(`Unable to parse ${pkgJSON}:`, e);
          reject(e)
          return
        }

        var dependenciesObj = pkg.packageDependencies;
        resolve(dependenciesObj)
      });
    });
  },

  _shouldInstallDependency(pkgName, latestVersion) {
    var pkg = atom.packages.loadPackage(pkgName);
    var currentVersion = (pkg === null) ? undefined : pkg.metadata.version;

    return !semver.satisfies(currentVersion, latestVersion);
  },

  _someDependencyIsMismatched() {
    var {packageDependencies} = require('../package.json');

    return Object.keys(packageDependencies).some(pkg => {
      var version = packageDependencies[pkg];
      return this._shouldInstallDependency(pkg, version)
    });
  },

  _updateFailed(detail) {
    var {shell, clipboard} = require('electron');

    var description = 'The installation seems to have been interrupted.';
    var buttons = [
      {
        text: 'Retry',
        onDidClick: () => this.update()
      },
      {
        text: 'Visit help center',
        onDidClick() { shell.openExternal(helpCenterUrl) }
      }
    ];

    if (detail != null) {
      description = 'Please include this information when contacting the Learn support team about the issue.';
      buttons.push({
        text: 'Copy this log',
        onDidClick() { clipboard.writeText(detail) }
      });
    }

    this.updateNotification =
      atom.notifications.addWarning('Learn IDE: update failed!', {detail, description, buttons, dismissable: true});
  },

  _updateSucceeded() {
    atom.notifications.addSuccess('Learn IDE: update successful!');
  }
};

