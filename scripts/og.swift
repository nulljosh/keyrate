// Draws web/og.png, the 1200x630 link preview: the icon and name, the headline, and a row of keycaps with the
// missed keys lit blue. Run from the repo root: swift scripts/og.swift
import AppKit

let W = 1200, H = 630
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H, bitsPerSample: 8, samplesPerPixel: 4,
                           hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ink = NSColor(srgbRed: 0.114, green: 0.114, blue: 0.122, alpha: 1), grey = NSColor(srgbRed: 0.431, green: 0.431, blue: 0.451, alpha: 1)
let blue = NSColor(srgbRed: 0, green: 0.478, blue: 1, alpha: 1), cap = NSColor(srgbRed: 0.961, green: 0.961, blue: 0.969, alpha: 1)
let line = NSColor(srgbRed: 0.898, green: 0.898, blue: 0.918, alpha: 1)
NSColor.white.setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()
func y(_ top: CGFloat, _ h: CGFloat) -> CGFloat { CGFloat(H) - top - h } // top-left coordinates
func text(_ s: String, _ size: CGFloat, _ weight: NSFont.Weight, _ color: NSColor, x: CGFloat, top: CGFloat, kern: CGFloat = 0) {
  let a: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color, .kern: kern]
  let str = NSAttributedString(string: s, attributes: a)
  str.draw(at: NSPoint(x: x, y: y(top, str.size().height)))
}
if let icon = NSImage(contentsOfFile: "web/brand/icon-1024.png") {
  let r = NSRect(x: 80, y: y(72, 88), width: 88, height: 88)
  NSGraphicsContext.saveGraphicsState(); NSBezierPath(roundedRect: r, xRadius: 20, yRadius: 20).addClip(); icon.draw(in: r); NSGraphicsContext.restoreGraphicsState()
}
text("Keyrate", 46, .semibold, ink, x: 192, top: 88, kern: -0.6)
text("Find your weak keys.", 92, .bold, ink, x: 76, top: 196, kern: -2.6)
text("A free typing test that lights up the keys you miss.", 34, .regular, grey, x: 80, top: 318)
let keys = Array("qwertyuiop"), lit: Set<Character> = ["e", "t", "o"]
let k: CGFloat = 88, gap: CGFloat = 16, x0: CGFloat = 80 // flush with the text above
for (i, ch) in keys.enumerated() {
  let r = NSRect(x: x0 + CGFloat(i) * (k + gap), y: y(440, k), width: k, height: k)
  let on = lit.contains(ch)
  if !on { line.setFill(); NSBezierPath(roundedRect: r.offsetBy(dx: 0, dy: -5), xRadius: 16, yRadius: 16).fill() }
  (on ? blue : cap).setFill(); let p = NSBezierPath(roundedRect: r, xRadius: 16, yRadius: 16); p.fill()
  if !on { line.setStroke(); p.lineWidth = 2; p.stroke() }
  let a: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 34, weight: .semibold), .foregroundColor: on ? NSColor.white : grey]
  let s = NSAttributedString(string: String(ch), attributes: a), sz = s.size()
  s.draw(at: NSPoint(x: r.midX - sz.width / 2, y: r.midY - sz.height / 2 + 2))
}
text("keyrate.jaybulb.com", 26, .medium, grey, x: 80, top: 560)
NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "web/og.png"))
print("web/og.png")
