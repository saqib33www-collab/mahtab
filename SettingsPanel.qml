import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
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
  property bool closingFromHost: false

  readonly property string pluginId: manifest && manifest.id ? manifest.id : "saqib33w.mahtab"
  readonly property bool popupBlocked: positionField.popupOpen || screenModeField.popupOpen
    || layoutField.popupOpen

  readonly property color scrim: Color.menu.scrim
  readonly property color cardBackground: Color.popups.background
  readonly property var cardBorderSpec: Border.surfaceSpec(
    "popups", "border", Color.popups.border, Math.max(1, Style.space(2))
  )
  readonly property int cardPadding: Style.spacing.panelPadding + Style.space(6)
  readonly property int contentGap: Style.space(16)

  property var draft: Clock.readSettings({})

  readonly property var positionOptions: [
    { value: "top-left", label: "Top left" },
    { value: "top-center", label: "Top center" },
    { value: "top-right", label: "Top right" },
    { value: "middle-left", label: "Middle left" },
    { value: "middle-center", label: "Middle center" },
    { value: "middle-right", label: "Middle right" },
    { value: "bottom-left", label: "Bottom left" },
    { value: "bottom-center", label: "Bottom center" },
    { value: "bottom-right", label: "Bottom right" }
  ]

  readonly property var screenModeOptions: [
    { value: "all", label: "All monitors" },
    { value: "primary", label: "Primary only" },
    { value: "focused", label: "Focused only" },
    { value: "external", label: "External only" }
  ]

  readonly property var layoutOptions: [
    { value: "mahtab", label: "Mahtab (greeting)" },
    { value: "grand", label: "Grand (big time)" }
  ]

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
    closingFromHost = false
    // Re-read shell.json on open so we never persist a stale/default draft over
    // saved settings.
    if (liveConfig) liveConfig.refresh()
    draft = Clock.readSettings(pluginEntry())
    root.opened = true
    Qt.callLater(function() {
      if (keyCatcher) keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    closingFromHost = true
    root.opened = false
    closingFromHost = false
  }

  function requestClose() {
    if (shell && typeof shell.hide === "function") shell.hide(root.pluginId)
    else root.close()
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "saqib33w-mahtab-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    onVisibleChanged: {
      if (!visible && !root.closingFromHost && root.shell && typeof root.shell.hide === "function")
        root.shell.hide(root.pluginId)
    }

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.requestClose()
    }

    BorderSurface {
      id: card
      anchors.centerIn: parent
      width: Math.min(Style.space(460), panel.width - Style.gapsOut * 6)
      height: Math.min(Style.space(620), panel.height - Style.gapsOut * 6)
      radius: Style.cornerRadius
      color: root.cardBackground
      borderSpec: root.cardBorderSpec
      padding: root.cardPadding

      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      FocusScope {
        id: contentScope
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        focus: true

        PanelKeyCatcher {
          id: keyCatcher
          anchors.fill: parent
          blocked: root.popupBlocked
          onCloseRequested: root.requestClose()
        }

        Column {
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
            height: contentScope.height
              - titleBlock.height
              - hintBlock.height
              - headerSep.height
              - root.contentGap * 3
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
              width: scroll.availableWidth
              spacing: root.contentGap

              PanelSectionHeader {
                width: parent.width
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

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
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

              Dropdown {
                id: positionField
                width: parent.width
                label: "Position"
                value: root.draft.position
                options: root.positionOptions
                onChanged: function(v) { root.patchDraft({ position: v, positionMode: "anchor" }) }
              }

              Button {
                width: parent.width
                text: "Drag to reposition"
                bordered: true
                focusable: true
                onClicked: {
                  if (root.service && typeof root.service.beginDragEdit === "function")
                    root.service.beginDragEdit()
                  root.requestClose()
                }
              }

              Text {
                width: parent.width
                visible: root.draft.positionMode === "free"
                wrapMode: Text.WordWrap
                text: "Using a dragged position. Pick a Position preset above to snap back to an anchor."
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

              SettingsSlider {
                bar: root.fakeBar
                label: "Scale"
                minimum: 0.4
                maximum: 4
                step: 0.05
                value: root.draft.scale
                valueText: root.draft.scale.toFixed(2)
                onMoved: function(v) { root.setDraft({ scale: v }) }
                onReleased: function(v) { root.patchDraft({ scale: v }) }
              }

              SettingsSlider {
                bar: root.fakeBar
                label: "Edge margin"
                minimum: 0
                maximum: 200
                step: 1
                value: root.draft.margin
                valueText: Math.round(root.draft.margin) + "px"
                onMoved: function(v) { root.setDraft({ margin: v }) }
                onReleased: function(v) { root.patchDraft({ margin: v }) }
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Time"
              }

              Toggle {
                width: parent.width
                label: "24-hour clock"
                description: "Show the hour in 24-hour format instead of 12-hour."
                checked: root.draft.use24h
                onClicked: root.patchDraft({ use24h: !root.draft.use24h })
              }

              PanelSeparator { width: parent.width }

              Button {
                width: parent.width
                text: "Reset to defaults"
                bordered: true
                focusable: true
                onClicked: root.resetDefaults()
              }

              Item {
                width: parent.width
                height: Style.space(12)
              }
            }
          }
        }
      }
    }
  }
}
