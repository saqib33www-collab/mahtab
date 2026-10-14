import QtQuick
import QtQuick.Effects
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

  // Writing the new scale to disk happens a moment after the last scroll tick,
  // so a fast flick doesn't hammer shell.json.
  Timer {
    id: scalePersist
    interval: 300
    repeat: false
    onTriggered: {
      if (root.pendingScale <= 0) return
      if (!(root.shell && typeof root.shell.updateEntryInline === "function")) return
      var merged = Clock.mergeSettings(root.pluginId, root.cfg, { scale: root.pendingScale })
      root.shell.updateEntryInline(root.pluginId, Clock.settingsToEntry(root.pluginId, merged))
    }
  }

  // Transient drag-to-reposition mode. Entered from the settings panel; while
  // active the clock is promoted above windows with a pointer mask limited to
  // its own bounds, so it can be grabbed and moved anywhere on the screen.
  property bool editActive: false

  // True while the clock is being dragged directly on the wallpaper (outside
  // edit mode). Blocks relayout from snapping it back mid-drag.
  property bool pointerDragActive: false

  // Scale set by scrolling over the clock. While > 0 it overrides cfg.scale for
  // instant feedback and is cleared once the persisted value round-trips back
  // through the config watcher.
  property real pendingScale: 0
  readonly property real liveScale: root.pendingScale > 0 ? root.pendingScale : root.cfg.scale

  // Scroll over the clock to resize. Steps in 0.05 to match the settings slider
  // and clamps to the same 0.4..4 range; the clockHost Connections react to
  // pendingScale for instant feedback and the value persists shortly after.
  function nudgeScale(dir) {
    var base = root.liveScale
    var next = Math.max(0.4, Math.min(4, Math.round((base + dir * 0.05) * 100) / 100))
    if (Math.abs(next - base) < 0.001) return
    root.pendingScale = next
    scalePersist.restart()
  }

  function beginDragEdit() {
    root.editActive = true
  }

  // Open the settings panel. Right-clicking the clock on the wallpaper summons
  // it through the same shell IPC the bar widget uses.
  function openSettings() {
    if (root.shell && typeof root.shell.summon === "function")
      root.shell.summon(root.pluginId, "{}")
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
    if (root.editActive || root.pointerDragActive) return

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
      // rest of the desktop keeps working underneath. Outside edit mode the mask
      // still clips input to the clock so a right-click on it can open settings —
      // windows sit above this layer, so it only takes clicks on empty wallpaper.
      mask: panel.clockVisible ? clockMask : null

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
        id: clockMask
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

        readonly property real fw: face.item ? face.item.implicitWidth : 0
        readonly property real fh: face.item ? face.item.implicitHeight : 0
        readonly property bool hasDate: root.cfg.dateShow && dateFace.item !== null
        readonly property real dw: clockHost.hasDate ? dateFace.item.implicitWidth : 0
        readonly property real dh: clockHost.hasDate ? dateFace.item.implicitHeight : 0
        readonly property real gap: (clockHost.hasDate && clockHost.dh > 0)
          ? Math.round(14 * root.liveScale) : 0

        // Soft halo behind the time so it reads on busy wallpapers. Always black.
        readonly property bool shadowOn: root.cfg.shadow
        readonly property color shadowTint: Qt.rgba(0, 0, 0, 0.6)

        width: Math.max(1, Math.max(clockHost.fw, clockHost.dw))
        height: Math.max(1, clockHost.fh + clockHost.gap + clockHost.dh)

        function relayout() {
          root.schedulePlaceClock(clockHost, panel)
        }

        // Push the live settings onto whichever face/date component the loaders
        // built. Colors that follow the theme (accent, card, font, corner) are
        // left to the faces' own bindings to the shell singletons so a theme
        // change recolors the clock live; only pinned overrides are pushed here.
        function applyFaceConfig(item) {
          if (!item) return
          item.faceScale = root.liveScale
          item.use24h = root.cfg.use24h
          item.ink = root.cfg.inkColor !== "" ? root.cfg.inkColor : "#ffffff"
          item.cardEnabled = root.cfg.cardEnabled
          item.cardAlpha = root.cfg.cardAlpha
          if ("showSeconds" in item) item.showSeconds = root.cfg.showSeconds
          if ("cardColor" in item && root.cfg.cardColor !== "") item.cardColor = root.cfg.cardColor
          if ("fontFamily" in item && root.cfg.fontFamily !== "") item.fontFamily = root.cfg.fontFamily
        }

        function faceFor(layout) {
          switch (layout) {
          case "grand": return grandComp
          case "digital": return digitalComp
          case "minimal": return minimalComp
          case "analog": return analogComp
          case "flip": return flipComp
          case "rings": return ringsComp
          case "bighour": return bigHourComp
          case "metal": return metalComp
          case "column": return columnComp
          case "outline": return outlineComp
          case "banner": return bannerComp
          default: return mahtabComp
          }
        }

        function dateFor(layout) {
          switch (layout) {
          case "badge": return dateBadgeComp
          case "stacked": return dateStackedComp
          default: return dateInlineComp
          }
        }

        Component.onCompleted: clockHost.relayout()

        DragHandler {
          id: dragHandler
          enabled: clockHost.visible
          target: null
          property real startX: 0
          property real startY: 0
          cursorShape: active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
          onActiveChanged: {
            if (active) {
              root.pointerDragActive = true
              dragHandler.startX = clockHost.x
              dragHandler.startY = clockHost.y
            } else {
              root.commitClockDrag(clockHost, panel)
              root.pointerDragActive = false
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
          text: "Drag to move · Scroll to resize · Esc to finish"
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
          function onCfgChanged() {
            if (root.pendingScale > 0 && Math.abs(root.cfg.scale - root.pendingScale) < 0.001)
              root.pendingScale = 0
            clockHost.applyFaceConfig(face.item)
            clockHost.applyFaceConfig(dateFace.item)
            clockHost.relayout()
          }
          function onPendingScaleChanged() {
            clockHost.applyFaceConfig(face.item)
            clockHost.applyFaceConfig(dateFace.item)
            clockHost.relayout()
          }
          function onClockInsetsChanged() { clockHost.relayout() }
          function onFocusedMonitorNameChanged() { clockHost.relayout() }
          function onInternalMonitorNameChanged() { clockHost.relayout() }
          function onEditActiveChanged() { clockHost.relayout() }
        }

        Connections {
          target: face.item
          function onImplicitWidthChanged() { clockHost.relayout() }
          function onImplicitHeightChanged() { clockHost.relayout() }
        }

        Connections {
          target: dateFace.item
          function onImplicitWidthChanged() { clockHost.relayout() }
          function onImplicitHeightChanged() { clockHost.relayout() }
        }

        Loader {
          id: face
          x: (clockHost.width - clockHost.fw) / 2
          y: 0
          sourceComponent: clockHost.faceFor(root.cfg.layout)
          layer.enabled: clockHost.shadowOn
          layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: clockHost.shadowTint
            shadowBlur: 0.85
            shadowVerticalOffset: 2
            shadowHorizontalOffset: 0
          }
          onItemChanged: {
            clockHost.applyFaceConfig(item)
            clockHost.relayout()
          }
        }

        Loader {
          id: dateFace
          x: (clockHost.width - clockHost.dw) / 2
          y: clockHost.fh + clockHost.gap
          active: root.cfg.dateShow
          visible: root.cfg.dateShow
          sourceComponent: root.cfg.dateShow ? clockHost.dateFor(root.cfg.dateLayout) : null
          layer.enabled: clockHost.shadowOn
          layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: clockHost.shadowTint
            shadowBlur: 0.85
            shadowVerticalOffset: 2
            shadowHorizontalOffset: 0
          }
          onItemChanged: {
            clockHost.applyFaceConfig(item)
            clockHost.relayout()
          }
        }

        // Right-click the clock on the wallpaper to open its settings, and scroll
        // over it to resize. Only the right button is accepted; the wheel is
        // handled regardless of button. Disabled in drag-edit mode (the
        // DragHandler owns input then), and the window mask confines input to
        // the clock.
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.RightButton
          enabled: !panel.editingHere
          cursorShape: dragHandler.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
          onClicked: root.openSettings()
          onWheel: function(wheel) {
            var d = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y
            if (d === 0) return
            root.nudgeScale(d > 0 ? 1 : -1)
            wheel.accepted = true
          }
        }

        Component { id: mahtabComp; MahtabFace {} }
        Component { id: grandComp; GrandFace {} }
        Component { id: digitalComp; DigitalFace {} }
        Component { id: minimalComp; MinimalFace {} }
        Component { id: analogComp; AnalogFace {} }
        Component { id: flipComp; FlipFace {} }
        Component { id: ringsComp; RingsFace {} }
        Component { id: bigHourComp; BigHourFace {} }
        Component { id: metalComp; MetalFace {} }
        Component { id: columnComp; ColumnFace {} }
        Component { id: outlineComp; OutlineFace {} }
        Component { id: bannerComp; BannerFace {} }
        Component { id: dateInlineComp; DateInlineFace {} }
        Component { id: dateBadgeComp; DateBadgeFace {} }
        Component { id: dateStackedComp; DateStackedFace {} }
      }
    }
  }
}
