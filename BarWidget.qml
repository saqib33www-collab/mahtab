import QtQuick
import qs.Commons
import qs.Ui
import "ClockModel.js" as Clock

// Bar toggle for the wallpaper "Mahtab" clock. Left click shows/hides the
// clock; right-click opens the settings panel. The show/hide choice is written
// back to this widget's shell.json entry so it survives restarts.
BarWidget {
  id: root
  moduleName: "saqib33w.mahtab"

  readonly property var shell: root.bar ? root.bar.shell : null

  // The plugin's service singleton, reached through the bar's scoped shell.
  // The settings panel is hosted outside the bar, so this widget lends it the
  // icon to drop out of and the bar surface to follow.
  readonly property var service: root.shell && typeof root.shell.serviceFor === "function"
    ? root.shell.serviceFor(root.moduleName) : null

  // Lend the anchor before the panel opens. Resolved straight off the bar at
  // call time: the scoped shell lands a beat after the bar itself, and reading
  // the `shell`/`service` bindings from a change handler can still return the
  // previous value.
  function lendPanelAnchor() {
    var barApi = root.bar
    var barShell = barApi ? barApi.shell : null
    var svc = barShell && typeof barShell.serviceFor === "function"
      ? barShell.serviceFor(root.moduleName) : null
    if (!svc) return
    svc.settingsAnchor = button
    svc.settingsBar = barApi
    svc.settingsOwner = root
  }

  onBarChanged: lendPanelAnchor()
  onShellChanged: lendPanelAnchor()
  Component.onCompleted: lendPanelAnchor()

  // The bar's hotkey navigation (Super+Ctrl+2 etc.) only counts a widget as a
  // panel when it carries open/close/opened, the same interface the built-in
  // bar panels use. Without these the Mahtab icon is skipped when the numbers
  // are handed out, so the shortcut lands on a neighbour.
  property bool opened: root.service ? root.service.settingsOpen === true : false

  function open() { root.openSettings() }

  function close() {
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide(root.moduleName)
  }

  // The bar prefers this over close() when another panel takes over, so the
  // outgoing card can fade in place instead of blinking out. The settings
  // panel reads the flag back off its owner (this widget) while closing.
  property bool popoutSwitchClosing: false

  function closeForPopoutSwitch() {
    root.popoutSwitchClosing = true
    root.close()
    Qt.callLater(function() { root.popoutSwitchClosing = false })
  }

  Component.onDestruction: {
    if (!root.service || root.service.settingsAnchor !== button) return
    root.service.settingsAnchor = null
    root.service.settingsBar = null
    root.service.settingsOwner = null
  }

  readonly property bool clockEnabled: Clock.asBool(root.setting("clockEnabled", true), true)

  function toggleClock() {
    var entry = { id: root.moduleName }
    for (var key in root.settings) if (key !== "id") entry[key] = root.settings[key]
    entry.clockEnabled = !root.clockEnabled

    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function openSettings() {
    // Point the hosted panel at this instance before summoning, so it opens
    // under the icon that was clicked.
    root.lendPanelAnchor()
    if (root.shell && typeof root.shell.summon === "function")
      root.shell.summon(root.moduleName, "{}")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰔚"
    slotSize: Style.bar.statusSlot
    active: root.clockEnabled
    useActiveColor: true
    tooltipText: root.clockEnabled
      ? "Mahtab clock: on — click to hide, right-click for settings"
      : "Mahtab clock: off — click to show, right-click for settings"
    onPressed: function(button) {
      if (button === Qt.RightButton) root.openSettings()
      else root.toggleClock()
    }
  }
}
