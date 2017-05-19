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

const util = {
  hoursBetweenChecks: 12,

  shouldSkipCheck() {
    var lastCheck = parseInt(localStorage.get('updateCheckDate'));
    var nextCheck = hoursBetweenChecks * 60 * 60;

    return (lastCheck + nextCheck) > Date.now()
  },

  latestVersionUrl() {
    var bleedingUpdates = atom.config.get(`${name}.bleedingUpdates`);
    return bleedingUpdates ? `${learnCo}/api/v1/learn_ide/bleeding_version` : `${learnCo}/api/v1/learn_ide/latest_version`
  },

  fetchLatestVersionData() {
    return fetch(this.latestVersionUrl()).then(data => {
      this.versionCache = data;
      return data;
    });
  },

  handleVersionData({version, detail}) {
    this.setCheckDate();

    if (this.shouldUpdate(version)) { util.addUpdateNotification(detail) }
  },

  shouldUpdate(latestVersion) {
    return pkgUpdater.shouldUpdate(latestVersion) || dependencyUpdater.shouldUpdate();
  },

  conditionallyInstallPackage() {
    return
      this.fetchLatestVersionData().then(({version}) => {
        if (this.shouldUpdatePackage(version)) {
          return this.installPackage(version)
        }
      })
  },

  parseInstallationResults({pkgResult, depResult}) {
    var log = '';
    var code = 0;

    if (pkgResult) {
      log += `Learn IDE:\n---\n${pkgResult.log}`;
      code += pkgResult.code;
    }

    if (depResult) {
      log += `\nDependencies:\n---\n${depResult.log}`;
      code += depResult.code;
    }

    return {log, success: (code === 0)}
  },

  setCheckDate() {
    localStorage.set('updateCheckDate', Date.now());
  },

  addUpToDateNotification() {
    atom.notifications.addSuccess('Learn IDE: up-to-date!');
  },

  addUpdateNotification(detail) {
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

  dissmissUpdateNotification() {
    if (this.updateNotification) { this.updateNotification.dismiss() }
  },

  addWaitNotification() {
    this.waitNotification =
      atom.notifications.addInfo('Please wait while the update is installed...', {
        description: 'This may take a few minutes. Please **do not** close the editor.',
        dismissable: true
      });
  },

  dissmissWaitNotification() {
    if (this.waitNotification) { this.waitNotification.dismiss() }
  },
}

export default {
  autoCheck() {
    if (util.shouldSkipCheck()) { return }

    util.fetchLatestVersionData().then(({version, detail}) => {
      util.setCheckDate();

      if (util.shouldUpdate(version)) { util.addUpdateNotification(detail) }
    }).catch(e => airbrake.notify(e));
  },

  checkForUpdate() {
    util.fetchLatestVersionData().then(({version, detail}) => {
      util.setCheckDate();

      if (util.shouldUpdate(version)) {
        util.addUpdateNotification(detail)
      } else {
        util.addUpToDateNotification();
      }
    }).catch(e => airbrake.notify(e));
  },

  update() {
    util.dissmissUpdateNotification()
    util.addWaitNotification()

    util.conditionallyInstallPackage.then(pkgResult => {
      util.installDependencies().then(depResult => {
        var {log, success} = util.parseResults({pkgResult, depResult});

        if (!success) {
          localStorage.delete('restartingForUpdate');
          util.dissmissWaitNotification()
          return
        }

        localStorage.set('updateLog', log)
        localStorage.set('restartingForUpdate', true);

        atom.restartApplication()
      })
    }).catch(e => util.updateFailed(e))
  },

  didRestartAfterUpdate() {
    var log = localStorage.remove('updateLog');
    var target = localStorage.remove('targetedUpdateVersion');

    this._shouldUpdate(target) ? this._updateFailed(log) : this._updateSucceeded()
  },

  _getLatestVersion() {
    if ((this.latestVersionData != null) && (this.latestVersionData.version != null)) {
      return Promise.resolve(this.latestVersionData.version);
    }

    return this._fetchLatestVersionData().then(({version}) => version);
  },

  _shouldUpdate(latestVersion) {
    return this._shouldUpdatePackage(latestVersion) || this._shouldUpdateDependencies();
  },

  _shouldUpdatePackage(latestVersion) {
    var {version} = require('../package.json');

    if (this._shouldRollback()) {
      return !semver.eq(latestVersion, version)
    }

    return semver.gt(latestVersion, version)
  },

  _shouldRollback() {
    var rollback = parseInt(localStorage.get('learn-ide:shouldRollback'));

    if (!rollback) { return false }

    var twelveHours = 12 * 60 * 60;
    var rollbackExpires = rollback + twelveHours;

    return rollbackExpires > Date.now()
  },

  _shouldUpdateDependencies() {
    var {packageDependencies} = require('../package.json');

    return Object.keys(packageDependencies).some(pkg => {
      var version = packageDependencies[pkg];
      return this._shouldInstallDependency(pkg, version)
    });
  },

  _shouldInstallDependency(pkgName, latestVersion) {
    var pkg = atom.packages.loadPackage(pkgName);
    var currentVersion = (pkg === null) ? undefined : pkg.metadata.version;

    return !semver.satisfies(currentVersion, latestVersion);
  },

  _shouldSkipCheck() {
    var twelveHours = 12 * 60 * 60;
    return this._lastCheckedAgo() < twelveHours;
  },

  _updatePackage() {
    return this._getLatestVersion().then(version => {
      localStorage.set('targetedUpdateVersion', version);
      if (!this._shouldUpdatePackage(version)) { return }
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

