// SPDX-FileCopyrightText: 2026 Starlight Brasil
// SPDX-License-Identifier: GPL-3.0-or-later

import * as Main from 'resource:///org/gnome/shell/ui/main.js';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

export default class StarlightClockRightExtension extends Extension {
    enable() {
        this._dateMenu = Main.panel.statusArea.dateMenu;
        this._dateMenuContainer = this._dateMenu?.container;
        this._rightBox = Main.panel._rightBox;

        if (!this._dateMenuContainer || !this._rightBox) {
            console.warn('Starlight Clock Right: GNOME panel date menu is unavailable');
            return;
        }

        this._originalParent = this._dateMenuContainer.get_parent();
        this._originalIndex = this._originalParent
            ? this._originalParent.get_children().indexOf(this._dateMenuContainer)
            : -1;

        this._moveToRightEdge();
    }

    disable() {
        if (!this._dateMenuContainer || !this._originalParent)
            return;

        this._moveToParent(
            this._dateMenuContainer,
            this._originalParent,
            this._originalIndex >= 0 ? this._originalIndex : 0
        );

        this._dateMenu = null;
        this._dateMenuContainer = null;
        this._rightBox = null;
        this._originalParent = null;
        this._originalIndex = -1;
    }

    _moveToRightEdge() {
        this._moveToParent(
            this._dateMenuContainer,
            this._rightBox,
            this._rightBox.get_n_children()
        );
    }

    _moveToParent(actor, parent, index) {
        const currentParent = actor.get_parent();
        if (currentParent)
            currentParent.remove_child(actor);

        parent.insert_child_at_index(actor, Math.min(index, parent.get_n_children()));
    }
}
