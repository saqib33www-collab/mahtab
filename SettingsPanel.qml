import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons
import qs.Ui
import "ClockModel.js" as Clock

// Settings panel for the "Mahtab" wallpaper clock. Summoned by the bar
// widget's right-click (or `omarchy-shell shell toggle saqib33w.mahtab`).
// Every change is written straight back to this plugin's shell.json entry, so
// the wallpaper clock updates live through ShellConfigWatcher.
Item {
  id: root

  property var shell: null
  property var manifest: null
  property var service: null
  property bool opened: false

  // Let the service throttle the wallpaper visualizer's repaint rate while this
  // panel is up, so configuring settings stays responsive during music.
  onOpenedChanged: {
    var svc = root.panelService
    if (svc) svc.settingsOpen = root.opened
  }

  readonly property string pluginId: manifest && manifest.id ? manifest.id : "saqib33w.mahtab"

  readonly property int contentGap: Style.space(16)

  // The panel entry point is loaded by the shell host outside the bar, so it
  // borrows the bar widget's icon and bar surface from the service singleton.
  // With both in hand it opens exactly like a built-in panel (Bluetooth,
  // Network, ...): a card that grows out of its bar icon, follows the bar's
  // theme, and dismisses on an outside click. Without them it still opens,
  // pinned to the screen corner rather than refusing to show.
  readonly property var panelService: {
    if (service) return service
    return shell && typeof shell.serviceFor === "function"
      ? shell.serviceFor(root.pluginId) : null
  }
  readonly property var barApi: panelService ? panelService.settingsBar : null
  readonly property var anchorItem: panelService ? panelService.settingsAnchor : null
  // Who the bar's popout coordinator should credit for this panel. It has to be
  // the bar widget, not this hosted panel: the open-panel underline compares
  // the popout owner against the widget sitting in the bar slot.
  readonly property var panelOwner: panelService && panelService.settingsOwner
    ? panelService.settingsOwner : root

  property var draft: Clock.readSettings({})

  // Which group of settings the panel shows; the footer symbols switch it.
  property string settingsTab: "clock"

  readonly property var screenModeOptions: [
    { value: "all", label: "All monitors" },
    { value: "primary", label: "Primary only" },
    { value: "focused", label: "Focused only" },
    { value: "external", label: "External only" }
  ]

  readonly property var layoutOptions: [
    { value: "mahtab", label: "Mahtab (greeting)" },
    { value: "grand", label: "Grand (big serif)" },
    { value: "digital", label: "Digital (mono)" },
    { value: "minimal", label: "Minimal" },
    { value: "analog", label: "Analog" },
    { value: "flip", label: "Flip (split-flap)" },
    { value: "rings", label: "Rings" },
    { value: "bighour", label: "Big hour" },
    { value: "metal", label: "Metal" },
    { value: "column", label: "Column" },
    { value: "outline", label: "Outline" },
    { value: "banner", label: "Banner" }
  ]

  readonly property var dateLayoutOptions: [
    { value: "inline", label: "Inline" },
    { value: "badge", label: "Badge" },
    { value: "stacked", label: "Stacked (calendar)" }
  ]

  readonly property var vizStyleOptions: [
    { value: "bars", label: "Bars" },
    { value: "split", label: "Split" },
    { value: "dots", label: "Dots" },
    { value: "segments", label: "Segments" },
    { value: "wave", label: "Wave" },
    { value: "ribbon", label: "Ribbon" },
    { value: "curtain", label: "Curtain" },
    { value: "line", label: "Line (scope)" },
    { value: "frame", label: "Frame" },
    { value: "radial", label: "Radial" },
    { value: "orb", label: "Orb" },
    { value: "spiral", label: "Spiral" }
  ]

  readonly property var vizShapeOptions: [
    { value: "rounded", label: "Rounded" },
    { value: "sharp", label: "Sharp" }
  ]

  readonly property var vizColorOptions: [
    { value: "accent", label: "Theme accent" },
    { value: "foreground", label: "Theme text" },
    { value: "rainbow", label: "Rainbow" },
    { value: "white", label: "White" }
  ]

  // Font choices mirror Omarchy's own font menu: omarchy-font-list returns the
  // system's monospace families (minus emoji/icon noise), so the picker stays
  // short and matches what appearance.font offers. The leading "" option keeps
  // the manifest default reachable, so the clock can always go back to
  // following the Omarchy theme font. Re-read on every panel open so fonts
  // installed later show up without reloading the shell.
  property var fontOptions: [
    { value: "", label: "Shell default" }
  ]
  property bool fontOptionsLoading: false

  function refreshFontOptions() {
    if (root.fontOptionsLoading) return
    root.fontOptionsLoading = true
    fontListProc.running = true
  }

  Process {
    id: fontListProc
    command: ["sh", "-c", "omarchy-font-list 2>/dev/null"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var out = [{ value: "", label: "Shell default" }]
        var lines = String(text || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
          var name = lines[i].trim()
          if (name) out.push({ value: name, label: name })
        }
        // Keep the last good list if the command produced nothing (e.g. the
        // omarchy CLI is missing); the default-only list also stays put.
        if (out.length > 1) root.fontOptions = out
        root.fontOptionsLoading = false
      }
    }
  }

  readonly property var fakeBar: QtObject {
    readonly property color foreground: Color.foreground
    readonly property color background: Color.background
    readonly property string fontFamily: Style.font.family
  }

  ShellConfigWatcher {
    id: liveConfig
    pluginId: root.pluginId
  }

  function pluginEntry() {
    return liveConfig.entry || {}
  }

  function mergeDraft(base, updates) {
    var merged = {}
    for (var k in base) merged[k] = base[k]
    for (var u in updates) merged[u] = updates[u]
    return Clock.readSettings(Clock.settingsToEntry(root.pluginId, merged))
  }

  function setDraft(updates) {
    draft = mergeDraft(root.draft, updates)
  }

  function patchDraft(updates) {
    root.draft = mergeDraft(root.draft, updates)
    persist()
  }

  function persist() {
    if (!shell || typeof shell.updateEntryInline !== "function") return
    shell.updateEntryInline(root.pluginId, Clock.settingsToEntry(root.pluginId, draft))
  }

  function resetToDefaults() {
    root.draft = Clock.readSettings({})
    persist()
  }

  function open(payloadJson) {
    // Re-read shell.json on open so we never persist a stale/default draft over
    // saved settings.
    if (liveConfig) liveConfig.refresh()
    draft = Clock.readSettings(pluginEntry())
    root.refreshFontOptions()
    // Build the popup content before opening so the panel can take keyboard
    // focus on the first frame and the card grows straight to its settled size.
    if (typeof panel.ensureContent === "function") panel.ensureContent()
    root.opened = true
  }

  function close() {
    root.opened = false
  }

  function requestClose() {
    if (shell && typeof shell.hide === "function") shell.hide(root.pluginId)
    else root.close()
  }

  // Built-in panels attach their card to the bar icon and dismiss on an
  // outside click; KeyboardPanel gives the same behaviour, animation, and
  // popout coordination. Without an anchor or bar surface (e.g. the bar widget
  // was removed) it still opens, pinned to the screen corner.
  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.panelOwner
    bar: root.barApi
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(460))
    contentHeight: panel.fittedContentHeight(Style.space(600))

    // Lazy content: built on the first open, then kept, so the settings cost
    // nothing until the user asks for them.
    content: PanelKeyCatcher {
      id: keyCatcher
      // Dropdown popups own the keyboard while they are open.
      blocked: screenModeField.popupOpen
        || layoutField.popupOpen || dateField.popupOpen
        || vizStyleField.popupOpen || vizShapeField.popupOpen || vizColorField.popupOpen
        || fontField.popupOpen
      onMoveRequested: function(dx, dy) {
        var f = scroll.contentItem
        if (!f || f.contentY === undefined) return
        var maxY = Math.max(0, f.contentHeight - f.height)
        f.contentY = Math.max(0, Math.min(maxY, f.contentY + dy * Style.space(48)))
      }
      onCloseRequested: root.requestClose()

      Column {
        id: chrome
        anchors.fill: parent
        spacing: root.contentGap

        Text {
          id: titleBlock
          width: parent.width
          text: "Mahtab"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
          topPadding: Style.space(2)
        }

        Text {
          id: hintBlock
          width: parent.width
          wrapMode: Text.WordWrap
          text: "Rendered on the wallpaper layer, so open windows cover it. Changes apply immediately."
          color: Qt.darker(Color.foreground, 1.35)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        PanelSeparator { id: headerSep; width: parent.width }

        ScrollView {
          id: scroll
          width: parent.width
          height: chrome.height
            - titleBlock.height
            - hintBlock.height
            - headerSep.height
            - footerSep.height
            - footer.height
            - root.contentGap * 5
          clip: true
          ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

          // A slim bar that stays visible on the right edge rather than
          // fading out, so it always reads as a scrollable list.
          ScrollBar.vertical: ScrollBar {
            id: vbar
            policy: ScrollBar.AlwaysOn
            width: Style.space(6)
            contentItem: Rectangle {
              implicitWidth: Style.space(6)
              radius: width / 2
              color: vbar.pressed
                ? Color.foreground
                : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.35)
            }
            background: Rectangle {
              radius: width / 2
              color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.08)
            }
          }

          Column {
            width: scroll.availableWidth
            spacing: root.contentGap

            Column {
              id: clockView
              width: parent.width
              spacing: root.contentGap
              visible: root.settingsTab === "clock"

              SectionHeader {
                width: parent.width
                kind: "clock"
                text: "Visibility"
              }

              Toggle {
                width: parent.width
                label: "Show clock"
                description: "Master visibility toggle for the wallpaper clock."
                checked: root.draft.clockEnabled
                onClicked: root.patchDraft({ clockEnabled: !root.draft.clockEnabled })
              }

              Toggle {
                width: parent.width
                label: "Show card"
                description: "Draw a rounded card behind the clock for readability on busy wallpapers."
                checked: root.draft.cardEnabled
                onClicked: root.patchDraft({ cardEnabled: !root.draft.cardEnabled })
              }

              Toggle {
                width: parent.width
                label: "Text shadow"
                description: "Draw a soft halo behind the time and date so they stay legible on busy wallpapers."
                checked: root.draft.shadow
                onClicked: root.patchDraft({ shadow: !root.draft.shadow })
              }

              PanelSeparator { width: parent.width }

              SectionHeader {
                width: parent.width
                kind: "clock"
                text: "Typeface"
              }

              FontDropdown {
                id: fontField
                width: parent.width
                label: "Clock font"
                value: root.draft.fontFamily
                options: root.fontOptions
                onChanged: function(v) { root.patchDraft({ fontFamily: v }) }
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Same monospace fonts as the Omarchy font menu. Shell default follows the Omarchy theme font."
                color: Qt.darker(Color.foreground, 1.35)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              PanelSeparator { width: parent.width }

              SectionHeader {
                width: parent.width
                kind: "clock"
                text: "Layout"
              }

              Dropdown {
                id: layoutField
                width: parent.width
                label: "Layout style"
                value: root.draft.layout
                options: root.layoutOptions
                onChanged: function(v) { root.patchDraft({ layout: v }) }
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Drag the clock on the wallpaper to move it, and scroll over it to resize."
                color: Qt.darker(Color.foreground, 1.35)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              Dropdown {
                id: screenModeField
                width: parent.width
                label: "Show on"
                value: root.draft.screenMode
                options: root.screenModeOptions
                onChanged: function(v) { root.patchDraft({ screenMode: v }) }
              }

              PanelSeparator { width: parent.width }

              SectionHeader {
                width: parent.width
                kind: "clock"
                text: "Time"
              }

              Toggle {
                width: parent.width
                label: "24-hour clock"
                description: "Show the hour in 24-hour format instead of 12-hour."
                checked: root.draft.use24h
                onClicked: root.patchDraft({ use24h: !root.draft.use24h })
              }

              Toggle {
                width: parent.width
                label: "Show seconds"
                description: "Show the seconds where the layout has room for them."
                checked: root.draft.showSeconds
                onClicked: root.patchDraft({ showSeconds: !root.draft.showSeconds })
              }

              Toggle {
                width: parent.width
                label: "Show date"
                description: "Stack a date strip centred under the time."
                checked: root.draft.dateShow
                onClicked: root.patchDraft({ dateShow: !root.draft.dateShow })
              }

              Dropdown {
                id: dateField
                width: parent.width
                visible: root.draft.dateShow
                label: "Date style"
                value: root.draft.dateLayout
                options: root.dateLayoutOptions
                onChanged: function(v) { root.patchDraft({ dateLayout: v }) }
              }
            }

            Column {
              id: vizView
              width: parent.width
              spacing: root.contentGap
              visible: root.settingsTab === "viz"

              SectionHeader { width: parent.width; kind: "viz"; text: "Visualizer" }

              Toggle {
                width: parent.width
                label: "Audio visualizer"
                description: "Draw a cava audio spectrum on the wallpaper, behind your windows."
                checked: root.draft.visualizer
                onClicked: root.patchDraft({ visualizer: !root.draft.visualizer })
              }

              Dropdown {
                id: vizStyleField
                width: parent.width
                visible: root.draft.visualizer
                label: "Visualizer style"
                value: root.draft.visualizerStyle
                options: root.vizStyleOptions
                onChanged: function(v) { root.patchDraft({ visualizerStyle: v }) }
              }

              Dropdown {
                id: vizShapeField
                width: parent.width
                visible: root.draft.visualizer
                label: "Visualizer shape"
                value: root.draft.visualizerShape
                options: root.vizShapeOptions
                onChanged: function(v) { root.patchDraft({ visualizerShape: v }) }
              }

              Dropdown {
                id: vizColorField
                width: parent.width
                visible: root.draft.visualizer
                label: "Visualizer color"
                value: root.draft.visualizerColor
                options: root.vizColorOptions
                onChanged: function(v) { root.patchDraft({ visualizerColor: v }) }
              }

              SettingsSlider {
                width: parent.width
                visible: root.draft.visualizer
                bar: root.fakeBar
                label: "Visualizer height"
                helpText: "Height of the tallest bars, in pixels."
                minimum: 16
                maximum: 900
                step: 2
                integer: true
                value: root.draft.visualizerHeight
                valueText: Math.round(root.draft.visualizerHeight) + "px"
                onMoved: function(v) { root.setDraft({ visualizerHeight: v }) }
                onReleased: function(v) { root.patchDraft({ visualizerHeight: v }) }
              }

              SettingsSlider {
                width: parent.width
                visible: root.draft.visualizer
                bar: root.fakeBar
                label: "Visualizer bottom margin"
                helpText: "Distance from the bottom screen edge, in pixels."
                minimum: 0
                maximum: 200
                step: 2
                integer: true
                value: root.draft.visualizerMargin
                valueText: Math.round(root.draft.visualizerMargin) + "px"
                onMoved: function(v) { root.setDraft({ visualizerMargin: v }) }
                onReleased: function(v) { root.patchDraft({ visualizerMargin: v }) }
              }

              SettingsSlider {
                width: parent.width
                visible: root.draft.visualizer
                bar: root.fakeBar
                label: "Visualizer bars"
                helpText: "Number of spectrum bands."
                minimum: 4
                maximum: 128
                step: 1
                integer: true
                value: root.draft.visualizerBars
                valueText: String(Math.round(root.draft.visualizerBars))
                onMoved: function(v) { root.setDraft({ visualizerBars: v }) }
                onReleased: function(v) { root.patchDraft({ visualizerBars: v }) }
              }

              SettingsSlider {
                width: parent.width
                visible: root.draft.visualizer
                bar: root.fakeBar
                label: "Visualizer width"
                helpText: "Share of the screen width the spectrum spans."
                minimum: 0.1
                maximum: 1
                step: 0.05
                value: root.draft.visualizerWidth
                valueText: Math.round(root.draft.visualizerWidth * 100) + "%"
                onMoved: function(v) { root.setDraft({ visualizerWidth: v }) }
                onReleased: function(v) { root.patchDraft({ visualizerWidth: v }) }
              }

              SettingsSlider {
                width: parent.width
                visible: root.draft.visualizer
                bar: root.fakeBar
                label: "Visualizer thickness"
                helpText: "Band width as a share of its slot."
                minimum: 0.05
                maximum: 1
                step: 0.05
                value: root.draft.visualizerThickness
                valueText: Math.round(root.draft.visualizerThickness * 100) + "%"
                onMoved: function(v) { root.setDraft({ visualizerThickness: v }) }
                onReleased: function(v) { root.patchDraft({ visualizerThickness: v }) }
              }

              SettingsSlider {
                width: parent.width
                visible: root.draft.visualizer
                bar: root.fakeBar
                label: "Visualizer glow"
                helpText: "Bloom around each band."
                minimum: 0
                maximum: 1
                step: 0.05
                value: root.draft.visualizerGlow
                valueText: Math.round(root.draft.visualizerGlow * 100) + "%"
                onMoved: function(v) { root.setDraft({ visualizerGlow: v }) }
                onReleased: function(v) { root.patchDraft({ visualizerGlow: v }) }
              }

              SettingsSlider {
                width: parent.width
                visible: root.draft.visualizer
                bar: root.fakeBar
                label: "Visualizer reflection"
                helpText: "Mirror the bars below the baseline."
                minimum: 0
                maximum: 1
                step: 0.05
                value: root.draft.visualizerReflection
                valueText: Math.round(root.draft.visualizerReflection * 100) + "%"
                onMoved: function(v) { root.setDraft({ visualizerReflection: v }) }
                onReleased: function(v) { root.patchDraft({ visualizerReflection: v }) }
              }

              SettingsSlider {
                width: parent.width
                visible: root.draft.visualizer
                bar: root.fakeBar
                label: "Visualizer segments"
                helpText: "Slices per band for the Segments style."
                minimum: 3
                maximum: 24
                step: 1
                integer: true
                value: root.draft.visualizerSegments
                valueText: String(Math.round(root.draft.visualizerSegments))
                onMoved: function(v) { root.setDraft({ visualizerSegments: v }) }
                onReleased: function(v) { root.patchDraft({ visualizerSegments: v }) }
              }

              Toggle {
                width: parent.width
                visible: root.draft.visualizer
                label: "Visualizer peak caps"
                description: "Falling caps above each bar (Bars and Segments)."
                checked: root.draft.visualizerPeaks
                onClicked: root.patchDraft({ visualizerPeaks: !root.draft.visualizerPeaks })
              }

              SettingsSlider {
                width: parent.width
                visible: root.draft.visualizer
                bar: root.fakeBar
                label: "Visualizer sensitivity"
                helpText: "Amplitude multiplier applied to every bar."
                minimum: 0.1
                maximum: 4
                step: 0.1
                value: root.draft.visualizerSensitivity
                valueText: root.draft.visualizerSensitivity.toFixed(1) + "x"
                onMoved: function(v) { root.setDraft({ visualizerSensitivity: v }) }
                onReleased: function(v) { root.patchDraft({ visualizerSensitivity: v }) }
              }

              SettingsSlider {
                width: parent.width
                visible: root.draft.visualizer
                bar: root.fakeBar
                label: "Visualizer opacity"
                helpText: "Peak opacity of the bars."
                minimum: 0
                maximum: 1
                step: 0.05
                value: root.draft.visualizerOpacity
                valueText: Math.round(root.draft.visualizerOpacity * 100) + "%"
                onMoved: function(v) { root.setDraft({ visualizerOpacity: v }) }
                onReleased: function(v) { root.patchDraft({ visualizerOpacity: v }) }
              }
            }

            PanelSeparator { width: parent.width }

            Button {
              width: parent.width
              text: "Reset to defaults"
              bordered: true
              focusable: true
              onClicked: root.resetToDefaults()
            }

            Item {
              width: parent.width
              height: Style.space(12)
            }
          }
        }

        PanelSeparator { id: footerSep; width: parent.width }

        SymbolFooter {
          id: footer
          width: parent.width
          active: root.settingsTab
          foreground: Color.foreground
          onSelected: function(tab) { root.settingsTab = tab }
        }
      }
    }
  }
}
