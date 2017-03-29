'use babel'

import TerminalEmulator from 'xterm';
import path from 'path';
import { $, View } from 'atom-space-pen-views';
import { BrowserWindow } from 'remote';
import { clipboard } from 'electron';

import bus from './event-bus';
import colors from './colors';
import localStorage from './local-storage';

TerminalEmulator.loadAddon('fit');

const popoutEmulatorFile = path.resolve(__dirname, 'popout-emulator.html');

class TerminalView extends View {
  static content() {
    return this.div({class: 'terminal-resizer tool-panel'}, () => {
      this.div({class: 'terminal-resize-handle', outlet: 'resizeHandle'});
      return this.div({class: 'emulator-container', outlet: 'emulatorContainer'});
    });
  }

  initialize(terminal) {
    this.terminal = terminal;
    this.emulator = new TerminalEmulator({cursorBlink: true, rows: 16});

    this.subscribe();
    this.attach();
  }

  subscribe() {
    this.emulator.on('data', data => {
      this.handleEmulatorData(data, event);
    });

    this.terminal.on('message', msg => {
      this.writeToEmulator(msg);
    });

    this.on('mousedown', '.terminal-resize-handle', e => {
      this.resizeByDragStarted(e);
    });

    bus.on('popout-emulator:data', data => {
      this.handleEmulatorData(data, event);
    });
  }

  attach() {
    atom.workspace.addBottomPanel({item: this});
    this.emulator.open(this.emulatorContainer[0]);
  }

  handleEmulatorData(data, event) {
    if ((event == null)) {
      this.terminal.send(data);
      return;
    }

    this.parseEmulatorDataEvent(event, data);
  }

  parseEmulatorDataEvent({which, ctrlKey, shiftKey}, data) {
    if (!ctrlKey || (process.platform === 'darwin')) {
      this.terminal.send(data);
      return;
    }

    if (shiftKey && (which === 67)) {
      // ctrl-C
      atom.commands.dispatch(this.element, 'core:copy');
      return;
    }

    if (shiftKey && (which === 86)) {
      // ctrl-V
      atom.commands.dispatch(this.element, 'core:paste');
      return;
    }

    if (which === 83) {
      // ctrl-s
      var view = atom.views.getView(atom.workspace);
      atom.commands.dispatch(view, 'learn-ide:save');
      return;
    }

    this.terminal.send(data);
  }

  loadPopoutEmulator() {
    return new Promise((resolve) => {
      localStorage.set('popout-emulator:css', colors.getCSS());

      this.popout = new BrowserWindow({show: false});
      this.popout.loadURL(`file://${popoutEmulatorFile}`);

      this.popout.once('ready-to-show', () => resolve(this.popout));
      this.popout.on('closed', () => this.show());
    });
  }

  hasPopoutEmulator() {
    return (this.popout != null) && !this.popout.isDestroyed();
  }

  focusPopoutEmulator() {
    if (this.hasPopoutEmulator()) {
      this.hide();
      this.popout.focus();
      return;
    }

    this.loadPopoutEmulator().then(() => {
      this.hide();
      this.popout.show();
    });
  }

  writeToEmulator(text) {
    this.emulator.write(text);

    if (this.hasPopoutEmulator()) {
      bus.emit('popout-emulator:write', text);
    }
  }

  copyText() {
    var selection = document.getSelection();
    var rawText = selection.toString();
    var preparedText = rawText.replace(/\u00A0/g, ' ').replace(/\s+(\n)?$/gm, '$1');

    clipboard.writeText(preparedText);
  }

  pasteText() {
    var rawText = clipboard.readText();
    var preparedText = rawText.replace(/\n/g, '\r');

    this.terminal.send(preparedText);
  }

  toggleFocus() {
    var hasFocus = document.activeElement === this.emulator.textarea;

    hasFocus ? this.transferFocus() : this.focusEmulator()
  }

  transferFocus() {
    atom.workspace.getActivePane().activate();
  }

  focusEmulator() {
    this.emulator.focus();
  }

  currentFontSize() {
    var $el = $(this.emulator.element);
    return parseInt($el.css('font-size'));
  }

  increaseFontSize() {
    this.setFontSize(this.currentFontSize() + 2);
  }

  decreaseFontSize() {
    var currentSize = this.currentFontSize();

    if (currentSize > 2) {
      this.setFontSize(currentSize - 2);
    }
  }

  resetFontSize() {
    var defaultSize = atom.config.defaultSettings.editor.fontSize;
    this.setFontSize(defaultSize);
  }

  setFontSize(size) {
    $(this.emulator.element).css('font-size', size);
    this.resizeTerminal();
  }

  resizeByDragStarted() {
    $(document).on('mousemove', e => this.resizeAfterDrag(e));
    $(document).on('mouseup', () => this.resizeByDragStopped());
  }

  resizeByDragStopped() {
    $(document).off('mousemove', e => this.resizeAfterDrag(e));
    $(document).off('mouseup', () => this.resizeByDragStopped());
  }

  resizeAfterDrag({pageY, which}) {
    var {top} = this.element.getBoundingClientRect();
    if (which !== 1) {
      this.resizeByDragStopped();
      return;
    }

    if (this.height() > 100) {
      this.resizeTerminal(pageY);
    }
  }

  resizeTerminal(top) {
    if (top == null) {
      top = this.element.getBoundingClientRect().top;
    }

    var height = (this.outerHeight() + this.offset().top) - top;

    // resize container and fit emulator inside it
    this.emulatorContainer.height(height - this.resizeHandle.height());
    this.emulator.fit();

    // then get emulator height and fit containers around it
    var rowHeight = parseInt(this.emulator.rowContainer.style.lineHeight);
    var newHeight = rowHeight * this.emulator.rows;

    this.emulatorContainer.height(newHeight);
    this.height(newHeight + this.resizeHandle.height());
  }
};

export default TerminalView

