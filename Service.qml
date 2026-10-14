import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "ClockModel.js" as Clock
import "PluginConfig.js" as Config

// Renders the "Mahtab" clock on the wallpaper layer (below windows), one
// card per monitor. Highly inspired by the Kronos Omarchy plugin (MASH2RAFI).
// Config lives in shell.json; ShellConfigWatcher keeps it
// live so edits from `omarchy bar set` apply without a shell restart.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string pluginId: manifest && manifest.id ? manifest.id : "saqib33w.mahtab"
  readonly property var cfg: Clock.readSettings(liveConfig.entry || { id: root.pluginId })
  readonly property var pos: Clock.parsePosition(root.cfg.position)

  ShellConfigWatcher {
    id: liveConfig
    pluginId: root.pluginId
  }

  // Transient drag-to-reposition mode. Entered from the settings panel; while
  // active the clock is promoted above windows with a pointer mask limited to
  // its own bounds, so it can be grabbed and moved anywhere on the screen.
  property bool editActive: false

  function beginDragEdit() {
    root.editActive = true
  }

  function endDragEdit() {
    root.editActive = false
  }

  function commitClockDrag(host, panel) {
    if (!host || !panel || panel.width <= 0 || panel.height <= 0) return
    var f = Clock.freeFractions(
      host.x, host.y, host.width, host.height, panel.width, panel.height
    )
    var merged = Clock.mergeSettings(root.pluginId, root.cfg, {
      positionMode: "free", posX: f.x, posY: f.y
    })
    if (root.shell && typeof root.shell.updateEntryInline === "function")
      root.shell.updateEntryInline(root.pluginId, Clock.settingsToEntry(root.pluginId, merged))
  }

  property string internalMonitorName: ""
  readonly property string focusedMonitorName: Hyprland.focusedMonitor
    ? String(Hyprland.focusedMonitor.name || "")
    : ""

  // Inset from the Omarchy bar when the clock shares its edge, so the card
  // never sits underneath the bar.
  readonly property string barPos: Clock.barPosition(shell)
  readonly property bool barVertical: Clock.barIsVertical(root.barPos, shell)
  readonly property int barClearance: Math.round(
    (root.barVertical ? Style.bar.sizeVertical : Style.bar.sizeHorizontal) + 14
  )
  readonly property var clockInsets: Clock.edgeInsets(
    root.cfg.position, root.barPos, root.barVertical, root.barClearance, root.cfg.barPadding
  )

  function shouldShowOnScreen(screen) {
    return Clock.shouldShowOnScreen(
      screen, root.cfg.screenMode, root.internalMonitorName, root.focusedMonitorName
    )
  }

  function placeClock(host, panel) {
    if (!host || !panel || panel.width <= 0 || panel.height <= 0) return
    if (root.editActive) return

    // Free placement wins: a dragged position is stored as a screen fraction so
    // it survives resolution changes and monitor swaps.
    if (root.cfg.positionMode === "free") {
      var fp = Clock.freePlacement(
        root.cfg.posX, root.cfg.posY, host.width, host.height, panel.width, panel.height
      )
      host.x = fp.x
      host.y = fp.y
      return
    }

    var m = root.cfg.margin
    var inset = root.clockInsets
    var x = 0
    var y = 0

    if (root.pos.alignH === "left") x = m + inset.left
    else if (root.pos.alignH === "right") x = panel.width - host.width - m - inset.right
    else x = (panel.width - host.width) / 2

    if (root.pos.verticalAlign === "top") y = m + inset.top
    else if (root.pos.verticalAlign === "bottom") y = panel.height - host.height - m - inset.bottom
    else y = (panel.height - host.height) / 2

    var placed = Clock.clampPlacement(x, y, host.width, host.height, panel.width, panel.height)
    host.x = placed.x
    host.y = placed.y
  }

  function schedulePlaceClock(host, panel) {
    placeDebounce.host = host
    placeDebounce.panel = panel
    placeDebounce.restart()
  }

  Timer {
    id: placeDebounce
    interval: 1
    repeat: false
    property var host: null
    property var panel: null
    onTriggered: root.placeClock(host, panel)
  }

  Component.onCompleted: {
    if (Clock.needsInternalMonitorName(root.cfg.screenMode)) root.refreshMonitorNames()
  }

  function refreshMonitorNames() {
    if (monitorStateProc.running) return
    monitorStateProc.running = true
  }

  Timer {
    interval: 5000
    running: Clock.needsInternalMonitorName(root.cfg.screenMode)
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshMonitorNames()
  }

  Process {
    id: monitorStateProc
    command: [
      "sh", "-c",
      "omarchy-monitor-state 2>/dev/null | sed -n '2p' | head -c 256"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.internalMonitorName = String(text || "").trim()
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData

      readonly property bool screenActive: Clock.screenReady(modelData)
      readonly property bool editingHere: root.editActive && screenActive
        && (root.focusedMonitorName === "" || String(modelData.name) === root.focusedMonitorName)
      readonly property bool clockVisible: screenActive
        && !remapGuard.remapping
        && (root.editActive
              ? editingHere
              : (root.cfg.clockEnabled !== false && root.shouldShowOnScreen(modelData)))

      screen: modelData
      visible: clockVisible
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      // While editing, only the clock's own bounds receive pointer events so the
      // rest of the desktop keeps working underneath.
      mask: panel.editingHere ? editorMask : null

      ScreenMoveRemap {
        id: remapGuard
        window: panel
      }

      WlrLayershell.namespace: "saqib33w-mahtab"
      WlrLayershell.layer: panel.editingHere ? WlrLayer.Overlay : WlrLayer.Bottom
      WlrLayershell.keyboardFocus: panel.editingHere
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      Region {
        id: editorMask
        item: clockHost
      }

      FocusScope {
        anchors.fill: parent
        visible: panel.editingHere
        focus: panel.editingHere
        onVisibleChanged: if (visible) forceActiveFocus()
        Keys.onEscapePressed: {
          root.commitClockDrag(clockHost, panel)
          root.endDragEdit()
        }
      }

      Item {
        id: clockHost
        visible: panel.clockVisible
        width: face.implicitWidth
        height: face.implicitHeight

        function relayout() {
          root.schedulePlaceClock(clockHost, panel)
        }

        Component.onCompleted: clockHost.relayout()

        DragHandler {
          id: dragHandler
          enabled: panel.editingHere
          target: null
          property real startX: 0
          property real startY: 0
          cursorShape: active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
          onActiveChanged: {
            if (active) {
              dragHandler.startX = clockHost.x
              dragHandler.startY = clockHost.y
            } else {
              root.commitClockDrag(clockHost, panel)
            }
          }
          onActiveTranslationChanged: {
            if (!active) return
            var p = Clock.clampVisible(
              dragHandler.startX + activeTranslation.x,
              dragHandler.startY + activeTranslation.y,
              clockHost.width, clockHost.height, panel.width, panel.height
            )
            clockHost.x = p.x
            clockHost.y = p.y
          }
        }

        Rectangle {
          anchors.fill: parent
          anchors.margins: -12
          radius: 12
          color: "transparent"
          border.width: 2
          border.color: Color.accent
          visible: panel.editingHere
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          y: -height - 10
          text: "Drag to move · Esc to finish"
          visible: panel.editingHere
          color: Color.accent
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        Connections {
          target: panel
          function onWidthChanged() { clockHost.relayout() }
          function onHeightChanged() { clockHost.relayout() }
          function onClockVisibleChanged() { clockHost.relayout() }
        }

        Connections {
          target: modelData
          enabled: modelData !== null && modelData !== undefined
          function onWidthChanged() { clockHost.relayout() }
          function onHeightChanged() { clockHost.relayout() }
        }

        Connections {
          target: root
          function onCfgChanged() { clockHost.relayout() }
          function onClockInsetsChanged() { clockHost.relayout() }
          function onFocusedMonitorNameChanged() { clockHost.relayout() }
          function onInternalMonitorNameChanged() { clockHost.relayout() }
          function onEditActiveChanged() { clockHost.relayout() }
        }

        Connections {
          target: face
          function onImplicitWidthChanged() { clockHost.relayout() }
          function onImplicitHeightChanged() { clockHost.relayout() }
        }

        MahtabFace {
          id: face
          ink: root.cfg.inkColor !== "" ? root.cfg.inkColor : Color.foreground
          fontFamily: root.cfg.fontFamily !== "" ? root.cfg.fontFamily : Style.font.family
          faceScale: root.cfg.scale
          use24h: root.cfg.use24h
          cardEnabled: root.cfg.cardEnabled
          cardColor: root.cfg.cardColor !== "" ? root.cfg.cardColor : Color.background
          cardAlpha: root.cfg.cardAlpha
          cornerRadius: Style.cornerRadius
        }
      }
    }
  }
}
