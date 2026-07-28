// SPDX-FileCopyrightText: 2026 Starlight Brasil
// SPDX-License-Identifier: GPL-3.0-or-later

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

export default class StarlightBrighterExtension extends Extension {
    enable() {
        // GNOME Shell automatically loads this extension's stylesheet.css.
    }

    disable() {
        // GNOME Shell automatically unloads the stylesheet on disable.
    }
}
