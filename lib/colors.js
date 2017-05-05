'use babel'

import fs from 'fs';
import path from 'path';
import atomHelper from './atom-helper';
import { name } from '../package.json';

const stylesheetPath = path.join(__dirname, '..', 'styles', 'terminal-colors.css');

const helper = {
  convertLegacyConfig() {
    var text = atom.config.get(`${name}.terminalFontColor`);
    atom.config.unset(`${name}.terminalFontColor`);

    if (text != null) {
      atom.config.set(`${name}.terminalColors.basic.foreground`, text);
    }

    var background = atom.config.get(`${name}.terminalBackgroundColor`);
    atom.config.unset(`${name}.terminalBackgroundColor`);

    if (background != null) {
      atom.config.set(`${name}.terminalColors.basic.background`, background);
    }
  },

  ansiObjectToArray(ansiColorsObject) {
    var colorArray = [];

    for (var indexish in ansiColorsObject) {
      var color = ansiColorsObject[indexish];
      var index = parseInt(indexish);

      colorArray[index] = color.toRGBAString();
    }

    return colorArray;
  },

  ansiArrayToObject(ansiColorsArray) {
    var colorObject = {};

    ansiColorsArray.forEach((color, index) => colorObject[index] = color);

    return colorObject;
  },

  buildCSS({foreground, background, ansiColors}) {
    var css = `.terminal {color: ${foreground}; background-color: ${background}}\
               .terminal .xterm-viewport {background-color: ${background}}\n`;

    ansiColors.forEach((color, index) => {
      css += `.terminal .xterm-color-${index} {color: ${color}}\
							.terminal .xterm-bg-color-${index} {background-color: ${color}}\n`
    });

    return css;
  },

  addStylesheet(css) {
    return new Promise((resolve, reject) => {
      fs.writeFile(stylesheetPath, css, (err) => {
        if (err != null) {
          console.warn('unable to write colors to file:', err);
          atomHelper.addStylesheet(css);
        }

        resolve();
      });
    });
  }
};

const colors = {
  apply() {
    helper.convertLegacyConfig();

    var css = this.getCSS();

    helper.addStylesheet(css).then(() =>
			atomHelper.reloadStylesheets()
		);
  },

  getCSS() {
    var foreground = atom.config.get(`${name}.terminalColors.basic.foreground`).toRGBAString();
    var background = atom.config.get(`${name}.terminalColors.basic.background`).toRGBAString();
    var ansiColors = helper.ansiObjectToArray(atom.config.get(`${name}.terminalColors.ansi`));

    return helper.buildCSS({foreground, background, ansiColors});
  },

  parseJSON(jsonString) {
    var scheme;

    if ((jsonString == null) || !jsonString.length) {
      return;
    }

    try {
      scheme = JSON.parse(jsonString);
    } catch (err) {
      atom.notifications.addWarning('Learn IDE: Unable to parse color scheme!', {
				description: 'The scheme you\'ve entered is invalid JSON. Did you export the complete JSON from [terminal.sexy](https://terminal.sexy)?'
			});
      return;
    }

    var {color, foreground, background} = scheme;
    var itemIsMissing = [color, foreground, background].some((i) => i == null)

    if (itemIsMissing) {
      atom.notifications.addWarning('Learn IDE: Unable to parse color scheme!', {
        description: 'The scheme you\'ve entered is incomplete. Be sure to export the complete JSON from [terminal.sexy](https://terminal.sexy)?'
      });
      return;
    }

    var ansiColorsObject = helper.ansiArrayToObject(color);

    atom.config.set(`${name}.terminalColors.ansi`, ansiColorsObject);
    atom.config.set(`${name}.terminalColors.basic`, {foreground, background});
  }
};

export default colors;

