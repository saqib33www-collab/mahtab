import QtQuick
import qs.Commons

// Full-surface host for the shared SpectrumField shader (ported from the Ryoku
// shell). Consumes already-eased cava `levels` (0..1, `bars` long) plus falling
// `peaks` and mean `energy`, builds the eight-stop colour ramp the shader sweeps
// from `colorMode`, and forwards the look knobs. It fills its parent, so a polar
// or frame look has the whole panel to work with; the box confines the rest.
Item {
  id: root

  property var levels: []
  property var peaks: []
  property real energy: 0

  property string style: "bars"
  property string shape: "rounded"
  property string colorMode: "accent"
  property real thickness: 0.58
  property real glow: 0.6
  property real reflection: 0
  property int segments: 10
  property bool peakCaps: false

  // The box the look lives in, as fractions of this surface.
  property real boxX: 0
  property real boxY: 0.58
  property real boxW: 1
  property real boxH: 0.42
  property string grow: "up"

  readonly property var ramp: root.buildRamp()

  function baseColor() {
    if (root.colorMode === "foreground") return Color.foreground
    if (root.colorMode === "white") return "#ffffff"
    return Color.accent
  }

  // Eight stops: rainbow sweeps the hue wheel; every other mode is a gentle
  // bass->treble walk of one colour, matching the shader's short-ramp rule.
  function buildRamp() {
    var out = []
    if (root.colorMode === "rainbow") {
      for (var r = 0; r < 8; r++)
        out.push(Qt.hsla(r / 7, 0.7, 0.6, 1))
      return out
    }
    var base = root.baseColor()
    for (var i = 0; i < 8; i++) {
      var f = 1 + ((i / 7) - 0.5) * 0.36
      out.push(f >= 1 ? Qt.lighter(base, f) : Qt.darker(base, 1 / f))
    }
    return out
  }

  SpectrumField {
    anchors.fill: parent

    levels: root.levels
    peaks: root.peaks
    energy: root.energy
    fade: 1
    ramp: root.ramp

    style: root.style
    shape: root.shape
    thickness: root.thickness
    reflection: root.reflection
    segments: root.segments
    peakCaps: root.peakCaps
    glow: root.glow

    boxX: root.boxX
    boxY: root.boxY
    boxW: root.boxW
    boxH: root.boxH
    grow: root.grow
  }
}
