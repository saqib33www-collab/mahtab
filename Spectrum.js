.pragma library

// cava frame parsing and the rise-fast / fall-slow envelope used by the mahtab
// visualizer strip. Kept free of Qt singletons so it runs as a plain library.

// cava is asked for raw ASCII frames: one line per frame, bands separated by
// ';', each value in 0..asciiMax. Normalise to 0..1 for the bar renderer.
function parseFrame(line, asciiMax) {
  var text = String(line || "").trim()
  if (!text) return []
  var parts = text.split(";")
  var max = asciiMax > 0 ? asciiMax : 1000
  var out = []
  for (var i = 0; i < parts.length; i++) {
    var v = Number(parts[i])
    if (!isFinite(v)) v = 0
    out.push(Math.max(0, Math.min(1, v / max)))
  }
  return out
}

// Resample raw cava bands to exactly n slots, interpolating between neighbours
// so a 48-band source fills a wider range without blocky steps. A mild power
// curve lifts quiet bands and `sensitivity` scales the whole set, clamped 0..1.
function resampleBands(raw, n, sensitivity) {
  var out = []
  var count = Math.max(1, n)
  var m = Array.isArray(raw) ? raw.length : 0
  var gain = Number.isFinite(sensitivity) ? sensitivity : 1
  for (var i = 0; i < count; i++) {
    var v
    if (m === 0) v = 0
    else if (m === 1) v = raw[0]
    else {
      var t = count === 1 ? 0 : i * (m - 1) / (count - 1)
      var lo = Math.floor(t)
      var hi = Math.min(m - 1, lo + 1)
      var f = t - lo
      v = raw[lo] * (1 - f) + raw[hi] * f
    }
    if (!isFinite(v) || v < 0) v = 0
    out.push(Math.max(0, Math.min(1, Math.pow(v, 0.72) * gain)))
  }
  return out
}

// One-pole ease toward `target` over `dt` seconds: short `attack` lets a band
// snap up on a transient, longer `decay` lets it fall away gently. k is the
// frame-rate independent step, so the motion looks the same at any tick rate.
function ease(cur, target, dt, attack, decay) {
  var tau = target > cur ? attack : decay
  var k = 1 - Math.exp(-dt / tau)
  return cur + (target - cur) * k
}
