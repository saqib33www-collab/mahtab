import Quickshell
import Quickshell.Io
import "PluginConfig.js" as Config

// Watches shell.json directly so the wallpaper clock reflects settings edited
// after the plugin was loaded. The scoped shell object the Service receives
// exposes `barConfig` as a one-time snapshot, so a live file watcher is the
// reliable source of truth.
FileView {
  id: root

  property string pluginId: ""
  property var entry: null

  path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
  watchChanges: true
  printErrors: false

  function refresh() {
    var raw = root.text() || ""
    if (!raw.trim()) return
    try {
      var parsed = JSON.parse(raw)
      root.entry = Config.findEntry(parsed, root.pluginId) || null
    } catch (e) {
      // Transient parse failure (e.g. caught mid-write) — keep the last good entry.
    }
  }

  onLoaded: refresh()
  onFileChanged: reload()
  onLoadFailed: function(error) {}
}
