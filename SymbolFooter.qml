import QtQuick
import qs.Commons

// The settings panel's bottom strip: the drawn clock and visualizer marks act as
// tabs that switch the panel between the clock settings and the visualizer
// settings. Both are centred so they read as a pair.
Item {
  id: root

  // Currently selected group ("clock" or "viz").
  property string active: "clock"
  property color foreground: Color.foreground

  signal selected(string tab)

  readonly property real iconSize: Math.max(16, Math.ceil(Style.font.caption * 1.5))

  implicitHeight: tabRow.implicitHeight

  Row {
    id: tabRow
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(24)

    SymbolTab {
      kind: "clock"
      iconSize: root.iconSize
      foreground: root.foreground
      active: root.active === "clock"
      onActivated: root.selected("clock")
    }

    SymbolTab {
      kind: "viz"
      iconSize: root.iconSize
      foreground: root.foreground
      active: root.active === "viz"
      onActivated: root.selected("viz")
    }
  }
}
