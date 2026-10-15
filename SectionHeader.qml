import QtQuick
import qs.Commons
import qs.Ui

// A panel section title with a drawn symbol to its left. `kind` picks the mark
// ("clock" or "viz"); anchored rather than positioner-based so the symbol and
// the label stay vertically centred on each other.
Item {
  id: root

  property string kind: "clock"
  property string text: ""
  property color foreground: Color.foreground

  readonly property real iconSize: Math.max(12, Math.ceil(Style.font.caption * 1.15))

  implicitHeight: Math.max(iconSize, label.implicitHeight)
  implicitWidth: iconSize + Style.space(8) + label.implicitWidth

  Loader {
    id: icon
    width: root.iconSize
    height: root.iconSize
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    sourceComponent: root.kind === "viz" ? vizMark : clockMark
  }

  PanelSectionHeader {
    id: label
    anchors.left: icon.right
    anchors.leftMargin: Style.space(8)
    anchors.verticalCenter: parent.verticalCenter
    foreground: root.foreground
    text: root.text
  }

  Component {
    id: clockMark
    ClockSymbol { color: Qt.darker(root.foreground, 1.4) }
  }

  Component {
    id: vizMark
    VizSymbol { color: Qt.darker(root.foreground, 1.4) }
  }
}
