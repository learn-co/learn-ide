'use babel'

import Notifier from './notifier'
import StatusView from './views/status'
import Terminal from './terminal'
import TerminalView from './terminal-view'
import airbrake from './airbrake'
import atomHelper from './atom-helper'
import auth from './auth'
import bus from './event-bus'
import colors from './colors'
import config from './config'
import localStorage from './local-storage'
import logout from './logout'
import remoteNotification from './remote-notification'
import token from './token'
import username from './username'
import updater from './updater'
import {CompositeDisposable} from 'atom'
import {name, version} from '../package.json'
import {shell} from 'electron'
import {getLabSlug} from './learn-open'

window.LEARN_IDE_VERSION = version;

const ABOUT_URL = `${config.learnCo}/ide/about`;
const FAQ_URL = `${config.learnCo}/ide/faq`;
const REPORT_ISSUE_URL = `${config.learnCo}/ide/report-issue`;

export default {
  token,

  activate(state) {
    this.subscriptions = new CompositeDisposable;

    this.activateMonitor();
    this.registerWindowsProtocol();
    this.disableFormerPackage();

    colors.apply();

    this.subscribeToLogin();

    this.waitForAuth = auth().then(() => {
      this.activateIDE(state);
    }).catch(() => {
      this.activateIDE(state);
    });
  },

  activateIDE(state) {
    this.isRestartAfterUpdate = localStorage.remove('restartingForUpdate') === 'true';

    if (this.isRestartAfterUpdate) {
      updater.didRestartAfterUpdate();
    }

    this.activateTerminal();
    this.activateStatusView(state);
    this.activateEventHandlers();
    this.activateSubscriptions();
    this.activateNotifier();
    this.activateUpdater();
    this.activateRemoteNotification();
  },

  activateTerminal() {
    this.term = new Terminal({
      host: config.host,
      port: config.port,
      path: config.path,
      token: this.token.get(),
      username: username.get(),
      labSlug: getLabSlug()
    });

    this.termView = new TerminalView(this.term);
  },

  activateStatusView(state) {
    this.statusView = new StatusView(state, this.term);
  },

  activateEventHandlers() {
    atomHelper.trackFocusedWindow();
    // tidy up when the window closes
    atom.getCurrentWindow().on('close', () => this.cleanup());
  },

  activateSubscriptions() {
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'learn-ide:toggle-terminal': () => this.termView.toggle(),
      'learn-ide:toggle-popout': () => this.termView.focusPopoutEmulator(),
      'learn-ide:toggle-focus': () => this.termView.toggleFocus(),
      'learn-ide:focus': () => this.termView.focusEmulator(),
      'learn-ide:reset-connection': () => this.term.reset(),
      'learn-ide:view-version': () => this.viewVersion(),
      'learn-ide:update-check': () => updater.checkForUpdate(),
      'learn-ide:about': () => this.about(),
      'learn-ide:faq': () => this.faq(),
      'learn-ide:report-issue': () => this.reportIssue()
    }));

    this.subscriptions.add(atom.commands.add('.terminal', {
      'core:copy': () => this.termView.clipboardCopy(),
      'core:paste': () => this.termView.clipboardPaste(),
      'learn-ide:reset-font-size': () => this.termView.resetFontSize(),
      'learn-ide:increase-font-size': () => this.termView.increaseFontSize(),
      'learn-ide:decrease-font-size': () => this.termView.decreaseFontSize(),
      'learn-ide:scroll-up': () => this.termView.scrollUp(),
      'learn-ide:scroll-down': () => this.termView.scrollDown(),
      'learn-ide:clear-terminal': () => this.term.send('')
    }));

    this.subscriptions.add(
      atom.config.onDidChange(`${name}.bleedingUpdates`, ({newValue}) => {
        var key = 'learn-ide:shouldRollback';
        var didSubscribe = newValue;

        didSubscribe ? localStorage.delete(key) : localStorage.set(key, Date.now())

        updater.checkForUpdate()
      })
    )

    this.subscriptions.add(
      atom.config.onDidChange(`${name}.notifier`, ({newValue}) => {
        newValue ? this.activateNotifier() : this.notifier.deactivate()
      })
    )

    this.subscriptions.add(
      atom.config.observe(`${name}.fontFamily`, (font) => {
        this.termView.setFontFamily(font)
      })
    )

    this.subscriptions.add(
      atom.config.observe(`${name}.fontSize`, (size) => {
        this.termView.setFontSize(size)
      })
    )

    this.subscriptions.add(
      atom.config.onDidChange(`${name}.terminalColors.basic`, () => colors.apply())
    )

    this.subscriptions.add(
      atom.config.onDidChange(`${name}.terminalColors.ansi`, () => colors.apply())
    )

    this.subscriptions.add(
      atom.config.onDidChange(`${name}.terminalColors.json`, ({newValue}) => {
        colors.parseJSON(newValue);
      })
    )
  },

  activateNotifier() {
    if (atom.config.get(`${name}.notifier`)) {
      this.notifier = new Notifier(this.token.get());
      this.notifier.activate();
    }
  },

  activateUpdater() {
    if (!this.isRestartAfterUpdate) {
      return updater.autoCheck();
    }
  },

  activateMonitor() {
   this.subscriptions.add(atom.onWillThrowError(err => {
     airbrake.notify(err.originalError);
   }))
  },

  activateRemoteNotification() {
    remoteNotification();
  },

  deactivate() {
    localStorage.delete('disableTreeView');
    localStorage.delete('terminalOut');
    this.termView = null;
    this.statusView = null;
    this.subscriptions.dispose();
    this.term.emitter.removeAllListeners();
  },

  subscribeToLogin() {
    this.subscriptions.add(atom.commands.add('atom-workspace',
      {'learn-ide:log-in-out': () => this.logInOrOut()})
    );
  },

  cleanup() {
    atomHelper.cleanup();
  },

  consumeStatusBar(statusBar) {
    this.waitForAuth.then(() => this.addLearnToStatusBar(statusBar));
  },

  logInOrOut() {
    (this.token.get() == null) ? atomHelper.resetPackage() : logout()
  },

  registerWindowsProtocol() {
    if (process.platform === 'win32') { require('./protocol') }
  },

  disableFormerPackage() {
    var pkgName = 'integrated-learn-environment';

    if (!atom.packages.isPackageDisabled(pkgName)) {
      atom.packages.disablePackage(pkgName);
    }
  },

  addLearnToStatusBar(statusBar) {
    var leftTiles = Array.from(statusBar.getLeftTiles());
    var rightTiles = Array.from(statusBar.getRightTiles());
    var rightMostTile = rightTiles[rightTiles.length - 1];

    var priority = ((rightMostTile != null ? rightMostTile.priority : undefined) || 0) - 1;
    statusBar.addRightTile({item: this.statusView, priority});
  },

  about() {
    shell.openExternal(ABOUT_URL);
  },

  faq() {
    shell.openExternal(FAQ_URL);
  },

  reportIssue() {
    shell.openExternal(REPORT_ISSUE_URL);
  },

  viewVersion() {
    atom.notifications.addInfo(`Learn IDE: v${version}`);
  }
};
