'use babel'

import localStorage from './local-storage';
import { name } from '../package.json';

export default {
  isLastFocusedWindow() {
    return parseInt(localStorage.get('lastFocusedWindow')) === process.pid;
  },

  setLastFocusedWindow() {
    localStorage.set('lastFocusedWindow', process.pid);
  },

  trackFocusedWindow() {
    this.setLastFocusedWindow();
    window.onfocus = this.setLastFocusedWindow;
  },

  cleanup() {
    if (this.isLastFocusedWindow()) {
      localStorage.delete('lastFocusedWindow');
    }
  },

  emit(key, detail) {
    atom.emitter.emit(key, detail);
  },

  on(key, callback) {
    return atom.emitter.on(key, callback);
  },

  closePaneItems() {
    atom.workspace.getPanes().forEach(pane => pane.close());
  },

  resetPackage() {
    atom.packages.deactivatePackage(name);

    atom.packages.activatePackage(name).then(() =>
			atom.menu.sortPackagesMenu()
		);
  },

  reloadStylesheets() {
    var pkg = atom.packages.getActivePackage(name);
    pkg.reloadStylesheets();
  },

  addStylesheet(css) {
    atom.styles.addStyleSheet(css);
  }
};

