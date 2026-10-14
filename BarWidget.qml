import QtQuick
import qs.Commons
import qs.Ui
import "ClockModel.js" as Clock

// Bar toggle for the wallpaper "Good-night" clock. Left click shows/hides the
// clock; right-click opens the settings panel. The show/hide choice is written
// back to this widget's shell.json entry so it survives restarts.
BarWidget {
  id: root
  moduleName: "saqib33w.goodnight"

  readonly property var shell: root.bar ? root.bar.shell : null

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
      ? "Good-night clock: on — click to hide, right-click for settings"
      : "Good-night clock: off — click to show, right-click for settings"
    onPressed: function(button) {
      if (button === Qt.RightButton) root.openSettings()
      else root.toggleClock()
    }
  }
}
