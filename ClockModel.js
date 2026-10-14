.pragma library

// Date/time helpers and the wallpaper-placement config used by Service.qml.
// Kept independent of Qt singletons so it can run as a plain library.

var WEEKDAYS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
var WEEKDAYS_TITLE = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
var WEEKDAYS_SHORT_TITLE = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
var MONTHS = [
  "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
  "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"
]
var MONTHS_TITLE = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
]

function pad2(value) {
  var n = Math.floor(Number(value) || 0)
  return (n < 10 ? "0" : "") + n
}

function clockParts(date, use24h) {
  var h = date.getHours()
  var m = date.getMinutes()
  var sec = date.getSeconds()
  var h12 = h % 12
  if (h12 === 0) h12 = 12
  var hh = use24h ? pad2(h) : pad2(h12)
  return {
    hh: hh,
    mm: pad2(m),
    ss: pad2(sec),
    ampm: h >= 12 ? "PM" : "AM",
    hours: h,
    minutes: m,
    seconds: sec,
    h12: h12,
    // smooth degrees, 12 o'clock = 0, clockwise.
    hourAngle: ((h % 12) + m / 60) * 30,
    minuteAngle: (m + sec / 60) * 6,
    secondAngle: sec * 6
  }
}

function dateParts(date) {
  var dow = date.getDay()
  var mon = date.getMonth()
  return {
    weekdayShort: WEEKDAYS[dow],
    weekdayShortTitle: WEEKDAYS_SHORT_TITLE[dow],
    weekday: WEEKDAYS_TITLE[dow],
    month: MONTHS[mon],
    monthTitle: MONTHS_TITLE[mon],
    dow: dow,
    mon: mon,
    year: date.getFullYear(),
    dom: date.getDate()
  }
}

function greeting(hour) {
  if (hour >= 5 && hour < 12) return "Morning"
  if (hour >= 12 && hour < 17) return "Afternoon"
  if (hour >= 17 && hour < 21) return "Evening"
  return "Night"
}

function clampNum(value, fallback, min, max) {
  var n = Number(value)
  if (!isFinite(n)) return fallback
  return Math.max(min, Math.min(max, n))
}

// shell.json may store booleans as real booleans (written by this plugin) or as
// strings like "true"/"false" (written by `omarchy bar set`). Coerce both.
function asBool(value, fallback) {
  if (value === undefined || value === null) return fallback
  if (value === true || value === false) return value
  if (typeof value === "string") {
    var v = value.trim().toLowerCase()
    if (v === "true" || v === "1" || v === "yes" || v === "on") return true
    if (v === "false" || v === "0" || v === "no" || v === "off") return false
    return fallback
  }
  if (typeof value === "number") return value !== 0
  return fallback
}

// ------------------------------------------------------------------ settings

function readSettings(entry) {
  entry = entry || {}
  return {
    clockEnabled: asBool(entry.clockEnabled, true),
    scale: clampNum(entry.scale !== undefined ? entry.scale : 1, 1, 0.4, 4),
    use24h: asBool(entry.use24h, false),
    showSeconds: asBool(entry.showSeconds, true),
    layout: normalizeLayout(entry.layout),
    dateShow: asBool(entry.dateShow, false),
    dateLayout: normalizeDateLayout(entry.dateLayout),
    position: String(entry.position || "middle-center"),
    margin: clampNum(entry.margin !== undefined ? entry.margin : 24, 24, 0, 400),
    barPadding: Math.max(0, Math.round(Number(entry.barPadding) || 0)),
    cardEnabled: asBool(entry.cardEnabled, false),
    shadow: asBool(entry.shadow, true),
    cardColor: String(entry.cardColor || ""),
    cardAlpha: clampNum(entry.cardAlpha !== undefined ? entry.cardAlpha : 0.9, 0.9, 0, 1),
    inkColor: String(entry.inkColor || ""),
    fontFamily: String(entry.fontFamily || ""),
    screenMode: normalizeScreenMode(entry.screenMode),
    positionMode: String(entry.positionMode || "anchor") === "free" ? "free" : "anchor",
    posX: clampNum(entry.posX !== undefined ? entry.posX : 0.5, 0.5, -2, 3),
    posY: clampNum(entry.posY !== undefined ? entry.posY : 0.5, 0.5, -2, 3)
  }
}

function settingsToEntry(pluginId, settings) {
  settings = settings || {}
  return {
    id: pluginId,
    clockEnabled: settings.clockEnabled,
    scale: settings.scale,
    use24h: settings.use24h,
    showSeconds: settings.showSeconds,
    layout: settings.layout,
    dateShow: settings.dateShow,
    dateLayout: settings.dateLayout,
    position: settings.position,
    margin: settings.margin,
    barPadding: settings.barPadding,
    cardEnabled: settings.cardEnabled,
    shadow: settings.shadow,
    cardColor: settings.cardColor,
    cardAlpha: settings.cardAlpha,
    inkColor: settings.inkColor,
    fontFamily: settings.fontFamily,
    screenMode: settings.screenMode,
    positionMode: settings.positionMode,
    posX: settings.posX,
    posY: settings.posY
  }
}

function mergeSettings(pluginId, base, updates) {
  base = base || {}
  updates = updates || {}
  var merged = {}
  for (var key in base) merged[key] = base[key]
  for (var ukey in updates) merged[ukey] = updates[ukey]
  return readSettings(settingsToEntry(pluginId, merged))
}

// -------------------------------------------------------------------- layout

var LAYOUTS = [
  "mahtab", "grand", "digital", "minimal", "analog", "flip", "rings",
  "bighour", "metal", "column", "outline", "banner"
]

function normalizeLayout(value) {
  var layout = String(value || "mahtab").toLowerCase()
  if (layout === "goodnight") layout = "mahtab"
  return LAYOUTS.indexOf(layout) >= 0 ? layout : "mahtab"
}

var DATE_LAYOUTS = ["inline", "badge", "stacked"]

function normalizeDateLayout(value) {
  var layout = String(value || "inline").toLowerCase()
  return DATE_LAYOUTS.indexOf(layout) >= 0 ? layout : "inline"
}

// ----------------------------------------------------------------- placement

function screenReady(screen) {
  return !!(screen && screen.name && screen.width > 0 && screen.height > 0)
}

function barPosition(shell) {
  var barPos = ""
  if (shell && shell.barConfig) barPos = String(shell.barConfig.position || "")
  if (barPos === "" && shell && shell.bar && shell.bar.vertical !== undefined)
    barPos = shell.bar.vertical ? "right" : (shell.barConfig ? String(shell.barConfig.position || "top") : "top")
  return barPos || "top"
}

function barIsVertical(barPos, shell) {
  return barPos === "left" || barPos === "right"
    || !!(shell && shell.bar && shell.bar.vertical)
}

function parsePosition(position) {
  var pos = String(position || "middle-center")
  var alignH = "center"
  if (pos.indexOf("left") !== -1) alignH = "left"
  else if (pos.indexOf("right") !== -1) alignH = "right"

  var verticalAlign = "middle"
  if (pos.indexOf("top") === 0) verticalAlign = "top"
  else if (pos.indexOf("bottom") === 0) verticalAlign = "bottom"

  return { alignH: alignH, verticalAlign: verticalAlign }
}

function edgeInsets(position, barPos, barVertical, clearance, manualPadding) {
  var insets = { top: 0, right: 0, bottom: 0, left: 0 }
  var pos = String(position || "middle-center")
  var onLeft = pos.indexOf("left") !== -1
  var onRight = pos.indexOf("right") !== -1
  var onTop = pos.indexOf("top") === 0
  var onBottom = pos.indexOf("bottom") === 0

  if (manualPadding > 0) {
    if (onTop) insets.top = manualPadding
    if (onBottom) insets.bottom = manualPadding
    if (onLeft) insets.left = manualPadding
    if (onRight) insets.right = manualPadding
    return insets
  }

  if (barPos === "top" && onTop) insets.top = clearance
  if (barPos === "bottom" && onBottom) insets.bottom = clearance
  if (barPos === "left" && onLeft) insets.left = clearance
  if ((barPos === "right" || barVertical) && onRight) insets.right = clearance
  return insets
}

function clampPlacement(x, y, itemW, itemH, panelW, panelH) {
  var maxX = Math.max(0, panelW - itemW)
  var maxY = Math.max(0, panelH - itemH)
  return {
    x: Math.max(0, Math.min(x, maxX)),
    y: Math.max(0, Math.min(y, maxY))
  }
}

// Free (dragged) placement stores the clock centre as a fraction of the panel,
// so it survives resolution and monitor changes.
// Minimum number of pixels of the clock kept on-screen when dragged.
var MIN_VISIBLE = 48

// Like clampPlacement, but allows the clock to hang off any edge as long as at
// least MIN_VISIBLE remains visible. This keeps vertical (and horizontal) drag
// usable even when the face is larger than the screen.
function clampVisible(x, y, itemW, itemH, panelW, panelH) {
  var vx = Math.min(MIN_VISIBLE, itemW)
  var vy = Math.min(MIN_VISIBLE, itemH)
  return {
    x: Math.max(MIN_VISIBLE - itemW, Math.min(x, panelW - MIN_VISIBLE)),
    y: Math.max(MIN_VISIBLE - itemH, Math.min(y, panelH - MIN_VISIBLE))
  }
}

function freePlacement(posX, posY, itemW, itemH, panelW, panelH) {
  var cx = clampNum(posX, 0.5, -2, 3) * panelW
  var cy = clampNum(posY, 0.5, -2, 3) * panelH
  return clampVisible(cx - itemW / 2, cy - itemH / 2, itemW, itemH, panelW, panelH)
}

function freeFractions(x, y, itemW, itemH, panelW, panelH) {
  if (panelW <= 0 || panelH <= 0) return { x: 0.5, y: 0.5 }
  return {
    x: clampNum((x + itemW / 2) / panelW, 0.5, -2, 3),
    y: clampNum((y + itemH / 2) / panelH, 0.5, -2, 3)
  }
}

// --------------------------------------------------------------- screen mode

var SCREEN_MODES = ["all", "primary", "focused", "external"]

function normalizeScreenMode(value) {
  var mode = String(value || "all").toLowerCase()
  return SCREEN_MODES.indexOf(mode) >= 0 ? mode : "all"
}

function shouldShowOnScreen(screen, mode, internalName, focusedName) {
  if (!screenReady(screen)) return false
  mode = normalizeScreenMode(mode)
  var name = String(screen.name || "")
  if (mode === "all") return true
  if (mode === "focused") return focusedName !== "" && name === focusedName
  if (mode === "primary") {
    if (internalName !== "") return name === internalName
    return focusedName !== "" && name === focusedName
  }
  if (mode === "external") {
    if (internalName !== "") return name !== internalName
    return focusedName !== "" && name !== focusedName
  }
  return true
}

function needsInternalMonitorName(mode) {
  mode = normalizeScreenMode(mode)
  return mode === "primary" || mode === "external"
}
