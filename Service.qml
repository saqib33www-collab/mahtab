import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "ClockModel.js" as Clock
import "Spectrum.js" as Sp
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
  readonly property bool vizOn: root.cfg.visualizer === true

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
    root.resetSpectrum()
    if (root.vizOn) root.startCava()
  }

  Component.onDestruction: root.stopCava()

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

  // ----------------------------------------------------------- audio visualizer

  readonly property int vizAsciiMax: 1000
  // cava.conf ships next to this file; resolve it relative to Service.qml.
  readonly property string cavaConfigPath:
    Qt.resolvedUrl("cava.conf").toString().replace("file://", "")

  // `vizRaw` holds the latest cava targets, `spectrum` the eased levels the
  // shader actually draws, `vizPeaks` the falling peak caps and `vizEnergy` the
  // peak level; all shared so one cava process drives every monitor.
  property var vizRaw: []
  property var spectrum: []
  property var vizPeaks: []
  property real vizEnergy: 0

  // Set by the settings panel while it is open. The visualizer keeps previewing
  // but at a lower rate, so the full-surface shader stops competing with the
  // panel for the GPU.
  property bool settingsOpen: false

  // True while the motion timer should run: sound is arriving, or the eased
  // levels / peaks have not settled at rest yet.
  property bool _vizActive: false

  function resetSpectrum() {
    var n = root.cfg.visualizerBars
    var seed = []
    for (var i = 0; i < n; i++) seed.push(0)
    root.vizRaw = seed.slice()
    root.spectrum = seed.slice()
    root.vizPeaks = seed.slice()
    root.vizEnergy = 0
    root._vizActive = false
  }

  function startCava() { if (!cava.running) cava.running = true }
  function stopCava() { if (cava.running) cava.running = false }

  // cava hands us raw band magnitudes. We only resample them to the bar count
  // here; the easing that makes the motion smooth runs on the motion timer at
  // the display rate, so it is never tied to cava's own frame pacing.
  function handleFrame(line) {
    if (!root.vizOn) return
    var raw = Sp.parseFrame(line, root.vizAsciiMax)
    if (raw.length === 0) return
    var target = Sp.resampleBands(
      raw, root.cfg.visualizerBars, root.cfg.visualizerSensitivity
    )
    root.vizRaw = target
    var mx = 0
    for (var i = 0; i < target.length; i++) if (target[i] > mx) mx = target[i]
    if (mx > 0.003 && !root._vizActive) {
      root._vizActive = true
      vizTicker.last = 0
      vizTicker.dwell = 0
    }
  }

  // One eased step toward the latest cava targets. attack/decay are time
  // constants, so the motion looks identical at any tick rate.
  function vizTick(dt) {
    var n = root.cfg.visualizerBars
    var raw = root.vizRaw
    var prev = root.spectrum
    var out = []
    var sum = 0
    var mx = 0
    for (var i = 0; i < n; i++) {
      var target = i < raw.length ? raw[i] : 0
      var cur = i < prev.length ? prev[i] : 0
      var v = Sp.ease(cur, target, dt, 0.03, 0.15)
      out.push(v)
      sum += v
      if (v > mx) mx = v
    }
    var pk = root.vizPeaks
    var np = []
    var peakMax = 0
    for (var p = 0; p < n; p++) {
      var cap = (p < pk.length ? pk[p] : 0) - dt * 0.5
      if (cap < 0) cap = 0
      var pv = out[p] > cap ? out[p] : cap
      np.push(pv)
      if (pv > peakMax) peakMax = pv
    }
    root.spectrum = out
    root.vizPeaks = np
    root.vizEnergy = mx

    // Settle once at zero, then stop ticking so a still picture is not
    // repainted. A later cava frame re-arms the timer.
    if (mx < 0.002 && peakMax < 0.002)
      root._vizActive = false
  }

  // The motion clock: a steady 30 fps (Ryoku's default), not vsync, so the
  // easing is regular and never inherits cava's frame pacing. It halves while
  // the settings panel is open and drops a tier under sustained load, and stops
  // entirely at rest.
  Timer {
    id: vizTicker
    property real last: 0
    property real overrun: 1
    property int tier: 0
    property double dwell: 0

    readonly property int baseFps: root.settingsOpen ? 15 : 30
    readonly property int fps: vizTicker.tier === 0
      ? vizTicker.baseFps : Math.max(12, Math.round(vizTicker.baseFps * 0.6))
    interval: Math.round(1000 / vizTicker.fps)
    repeat: true
    running: root.vizOn && root._vizActive

    onTriggered: {
      var now = Date.now()
      var asked = vizTicker.interval / 1000
      var dt = vizTicker.last > 0 ? (now - vizTicker.last) / 1000 : asked
      vizTicker.last = now
      if (vizTicker.dwell === 0) vizTicker.dwell = now
      // Climb a tier on a slow average of the overrun, with a dwell, so a single
      // hitch never trips a change.
      vizTicker.overrun += (Math.min(3, dt / asked) - vizTicker.overrun) * 0.1
      if (now - vizTicker.dwell > 2500) {
        if (vizTicker.overrun > 1.6 && vizTicker.tier === 0) {
          vizTicker.tier = 1
          vizTicker.dwell = now
        } else if (vizTicker.overrun < 1.15 && vizTicker.tier === 1) {
          vizTicker.tier = 0
          vizTicker.dwell = now
        }
      }
      root.vizTick(Math.min(0.05, dt))
    }
  }

  Process {
    id: cava
    command: ["cava", "-p", root.cavaConfigPath]
    stdout: SplitParser {
      onRead: function(line) { root.handleFrame(line) }
    }
    onExited: if (root.vizOn) cavaRestart.restart()
  }

  // A moment after cava dies, bring it back — but only while the visualizer is
  // meant to be up, and not on top of an immediate restart storm.
  Timer {
    id: cavaRestart
    interval: 1500
    repeat: false
    onTriggered: if (root.vizOn) root.startCava()
  }

  onCfgChanged: root.resetSpectrum()
  onVizOnChanged: root.vizOn ? root.startCava() : root.stopCava()

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData

      readonly property bool screenActive: Clock.screenReady(modelData)
      readonly property bool editingHere: root.editActive && screenActive
        && (root.focusedMonitorName === "" || String(modelData.name) === root.focusedMonitorName)
      readonly property bool clockShown: root.cfg.clockEnabled !== false
        && root.shouldShowOnScreen(modelData)
      readonly property bool clockVisible: screenActive
        && !remapGuard.remapping
        && (root.editActive ? editingHere : panel.clockShown)
      // The optional visualizer strip shares the clock's screen targeting.
      readonly property bool spectrumVisible: screenActive
        && !remapGuard.remapping
        && root.vizOn
        && root.shouldShowOnScreen(modelData)

      screen: modelData
      visible: panel.clockVisible || panel.spectrumVisible
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      // While editing, or while the clock is being grabbed directly, take over
      // the whole surface so the drag never loses the pointer. Otherwise clip
      // input to the clock so a right-click on it can open settings — windows
      // sit above this layer, so it only takes clicks on empty wallpaper. When
      // only the (input-free) spectrum is up, the mask stays empty so clicks
      // fall straight through.
      mask: root.pointerDragActive ? null
        : (panel.clockVisible ? clockMask : emptyMask)

      ScreenMoveRemap {
        id: remapGuard
        window: panel
      }

      WlrLayershell.namespace: "saqib33w-mahtab"
      // Promote above windows while dragging (either from the settings panel or
      // by grabbing the clock directly) so it slides smoothly instead of being
      // occluded by whatever is underneath the pointer.
      WlrLayershell.layer: (panel.editingHere || root.pointerDragActive)
        ? WlrLayer.Overlay : WlrLayer.Bottom
      WlrLayershell.keyboardFocus: panel.editingHere
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      Region {
        id: clockMask
        item: clockHost
      }

      // Empty input region: makes the surface fully click-through when only the
      // decorative spectrum is visible.
      Region {
        id: emptyMask
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

      // Optional audio visualizer, sharing the clock's surface so a polar or
      // frame look gets the whole panel to work with. Purely decorative: the
      // surface's input mask never covers it.
      VisualizerStrip {
        id: spectrumStrip
        visible: panel.spectrumVisible
        anchors.fill: parent
        opacity: root.cfg.visualizerOpacity

        levels: root.spectrum
        peaks: root.vizPeaks
        energy: root.vizEnergy

        style: root.cfg.visualizerStyle
        shape: root.cfg.visualizerShape
        colorMode: root.cfg.visualizerColor
        thickness: root.cfg.visualizerThickness
        glow: root.cfg.visualizerGlow
        reflection: root.cfg.visualizerReflection
        segments: root.cfg.visualizerSegments
        peakCaps: root.cfg.visualizerPeaks

        // The look's box: a full-width band the width/height/margin settings
        // size and lift off the bottom edge. A polar look centres in it; a frame
        // look ignores it and wraps the whole panel.
        boxW: root.cfg.visualizerWidth
        boxX: (1 - root.cfg.visualizerWidth) / 2
        boxH: Math.min(1, root.cfg.visualizerHeight / Math.max(1, panel.height))
        boxY: Math.max(0, 1 - boxH - root.cfg.visualizerMargin / Math.max(1, panel.height))
        grow: "up"
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
