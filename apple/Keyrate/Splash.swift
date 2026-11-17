import SwiftUI

/// The brand mark on its 1024 grid (brand/mark.svg): four keys, three staggered under them, a space bar.
/// `missed` draws only the middle key of the second row, the one the icon paints red; otherwise every other key.
struct KeycapsMark: Shape {
    var missed = false
    func path(in r: CGRect) -> Path {
        let s = min(r.width, r.height) / 1024, ox = r.midX - 512 * s, oy = r.midY - 512 * s
        let top: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [161, 345, 529, 713].map { ($0, 262, 150, 150) }
        let mid: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [253, 621].map { ($0, 446, 150, 150) }
        let keys = missed ? [(437, 446, 150, 150)] : top + mid + [(345, 630, 518, 93)]
        var p = Path()
        for (x, y, w, h) in keys {
            p.addRoundedRect(in: CGRect(x: ox + x * s, y: oy + y * s, width: w * s, height: h * s), cornerSize: CGSize(width: 30 * s, height: 30 * s))
        }
        return p
    }
}

/// Launch splash: the keys draw in, fill (the missed one red), then scale away. About 1.1 s, once per launch.
struct Splash: View {
    @Binding var shown: Bool
    let bg: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var trim: CGFloat = 0
    @State private var fill = 0.0
    @State private var out = false
    @Environment(\.colorScheme) private var scheme
    private var ink: Color { scheme == .dark ? Color(red: 0.953, green: 0.929, blue: 0.878) : Color(red: 0.122, green: 0.106, blue: 0.086) }
    private var miss: Color { scheme == .dark ? Color(red: 1, green: 0.271, blue: 0.227) : Color(red: 0.843, green: 0, blue: 0.082) }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            ZStack {
                KeycapsMark().fill(ink.opacity(fill))
                KeycapsMark(missed: true).fill(miss.opacity(fill))
                KeycapsMark().trim(from: 0, to: trim).stroke(ink, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                KeycapsMark(missed: true).trim(from: 0, to: trim).stroke(miss, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }
            .frame(width: 140, height: 140)
            .scaleEffect(out ? 3 : 1)
        }
        .opacity(out ? 0 : 1)
        .accessibilityHidden(true)
        .task {
            if reduceMotion { trim = 1; fill = 1; try? await Task.sleep(for: .milliseconds(300)); withAnimation(.easeOut(duration: 0.2)) { out = true } }
            else {
                withAnimation(.easeInOut(duration: 0.5)) { trim = 1 }
                try? await Task.sleep(for: .milliseconds(450))
                withAnimation(.easeIn(duration: 0.25)) { fill = 1 }
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation(.easeIn(duration: 0.35)) { out = true }
            }
            try? await Task.sleep(for: .milliseconds(380))
            shown = false
        }
    }
}
