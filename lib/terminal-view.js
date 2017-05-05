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

    this.attach();
    this.subscribe();
  }

  attach() {
    atom.workspace.addBottomPanel({item: this});
    this.emulator.open(this.emulatorContainer[0]);
    this.restoreEmulatorSize()
  }

  subscribe() {
    this.emulator.attachCustomKeydownHandler(e => {
      this.catchSaveShortcutOnWindowsOrLinux(e);
    })

    this.emulator.on('data', data => {
      this.sendToTerminal(data, event);
    });

    this.terminal.on('message', msg => {
      this.writeToEmulator(msg);
    });

    bus.on('popout-emulator:data', data => {
      this.sendToTerminal(data);
    });

    this.on('mousedown', '.terminal-resize-handle', e => {
      this.resizeByDragStarted(e);
    });
  }

  sendToTerminal(data) {
    this.terminal.send(data)
  }

  writeToEmulator(text) {
    this.emulator.write(text);

    if (this.hasPopoutEmulator()) {
      bus.emit('popout-emulator:write', text);
    }
  }

  catchSaveShortcutOnWindowsOrLinux(e) {
    var {which, ctrlKey} = e;

    if (ctrlKey && (which === 83) && (process.platform !== 'darwin')) {
      // ctrl-s on win32 or linux
      var view = atom.views.getView(atom.workspace);
      atom.commands.dispatch(view, 'learn-ide:save');

      e.preventDefault()
    }
  }

  loadPopoutEmulator() {
    return new Promise((resolve) => {
      localStorage.set('popout-emulator:css', colors.getCSS());

      this.popout = new BrowserWindow({title: 'Learn IDE Terminal', show: false, autoHideMenuBar: true});
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

  clipboardCopy() {
    var selection = document.getSelection();
    var rawText = selection.toString();
    var preparedText = rawText.replace(/\u00A0/g, ' ').replace(/\s+(\n)?$/gm, '$1');

    clipboard.writeText(preparedText);
  }

  clipboardPaste() {
    var rawText = clipboard.readText();
    var preparedText = rawText.replace(/\n/g, '\r');

    this.sendToTerminal(preparedText);
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
    return parseInt(this.emulatorContainer.css('font-size'));
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
    if (this.forcedStyle != null) {
      this.forcedStyle.remove()
      delete this.forcedStyle
    }

    localStorage.set('learn-ide:currentFontSize', size)
    this.emulatorContainer.css('font-size', size);
    this.resizeTerminal();
  }

  forceFontSize(size) {
    this.forcedStyle = document.createElement('style')
    var selector = `.${this.emulatorContainer.attr('class')}`
    this.forcedStyle.innerHTML = `${selector} { font-size: ${size}px !important }`

    document.head.appendChild(this.forcedStyle)
    this.resizeTerminal()
  }

  restoreEmulatorSize() {
    var fontSize = localStorage.get('learn-ide:currentFontSize')
    var storedProperties = JSON.parse(localStorage.get('learn-ide:currentEmulatorSize'))

    if (storedProperties == null) { return }

    var {viewHeight, emulatorContainerHeight} = storedProperties

    this.height(viewHeight)
    this.emulatorContainer.height(emulatorContainerHeight)

    if (fontSize == null) { return }

    this.forceFontSize(fontSize)
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
    if (which !== 1) {
      this.resizeByDragStopped();
      return;
    }

    this.resizeTerminal(pageY);
  }

  resizeTerminal(top) {
    if (top == null) {
      top = this.element.getBoundingClientRect().top;
    }

    var height = (this.outerHeight() + this.offset().top) - top;

    if (height < 100) { return; }

    // resize container and fit emulator inside it
    this.emulatorContainer.height(height - this.resizeHandle.height());
    this.emulator.fit();

    // then get emulator height and fit containers around it
    var rowHeight = parseInt(this.emulator.rowContainer.style.lineHeight);
    var newHeight = rowHeight * this.emulator.rows;

    this.emulatorContainer.height(newHeight);
    this.height(newHeight + this.resizeHandle.height());
    this.cacheEmulatorSize()
  }

  cacheEmulatorSize() {
    var size = {
      viewHeight: this.height(),
      emulatorContainerHeight: this.emulatorContainer.height()
    };

    localStorage.set('learn-ide:currentEmulatorSize', JSON.stringify(size))
  }
}

export default TerminalView

