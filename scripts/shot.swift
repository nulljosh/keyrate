// Screenshots a page with WebKit, no browser needed: swift scripts/shot.swift <url> <out.png> [width] [height] [light|dark] [wait seconds]
// Used for the README and store images. Chrome headless hangs on this Mac and Playwright isn't installed.
import AppKit
import WebKit

let a = CommandLine.arguments
guard a.count >= 3 else { print("usage: shot.swift <url> <out.png> [width] [height] [light|dark] [wait]"); exit(2) }
let url = URL(string: a[1])!, out = URL(fileURLWithPath: a[2])
let w = a.count > 3 ? Double(a[3])! : 1440, h = a.count > 4 ? Double(a[4])! : 900
let dark = a.count > 5 && a[5] == "dark", wait = a.count > 6 ? Double(a[6])! : 3

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let window = NSWindow(contentRect: NSRect(x: -10000, y: 0, width: w, height: h), styleMask: [.borderless], backing: .buffered, defer: false)
window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua) // drives prefers-color-scheme in the page
let web = WKWebView(frame: NSRect(x: 0, y: 0, width: w, height: h))
web.appearance = window.appearance
window.contentView = web
window.orderFrontRegardless()

final class Done: NSObject, WKNavigationDelegate {
  func webView(_ v: WKWebView, didFinish _: WKNavigation!) {
    DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
      let c = WKSnapshotConfiguration(); c.rect = NSRect(x: 0, y: 0, width: w, height: h)
      v.takeSnapshot(with: c) { img, err in
        guard let img, let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { print("failed: \(String(describing: err))"); exit(1) }
        try! png.write(to: out); print(out.path); exit(0)
      }
    }
  }
  func webView(_: WKWebView, didFail _: WKNavigation!, withError e: Error) { print("failed: \(e)"); exit(1) }
  func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError e: Error) { print("failed: \(e)"); exit(1) }
}
let done = Done()
web.navigationDelegate = done
web.load(URLRequest(url: url))
DispatchQueue.main.asyncAfter(deadline: .now() + 60) { print("timed out"); exit(1) }
app.run()
