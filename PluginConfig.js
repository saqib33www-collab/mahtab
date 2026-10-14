.pragma library

// Reads a plugin's settings entry out of the parsed shell.json, preferring a
// bar-layout entry (where `omarchy bar set` writes) and falling back to a
// top-level plugins[] entry.

function findEntryInBarConfig(barConfig, pluginId) {
  if (!barConfig || !barConfig.layout) return null
  var sections = ["left", "center", "right"]
  for (var s = 0; s < sections.length; s++) {
    var arr = barConfig.layout[sections[s]] || []
    for (var i = 0; i < arr.length; i++) {
      var entry = arr[i]
      if (entry && String(entry.id || "") === pluginId) return entry
    }
  }
  return null
}

function findEntryInPlugins(parsed, pluginId) {
  if (!parsed || !Array.isArray(parsed.plugins)) return null
  for (var i = 0; i < parsed.plugins.length; i++) {
    var entry = parsed.plugins[i]
    if (entry && String(entry.id || "") === pluginId) return entry
  }
  return null
}

function findEntry(parsed, pluginId) {
  if (!parsed) return null
  return findEntryInBarConfig(parsed.bar, pluginId) || findEntryInPlugins(parsed, pluginId)
}
