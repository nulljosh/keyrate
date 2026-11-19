import SwiftUI

/// Progress: what this device has saved, drawn in Keyrate's palette and laid out to the window. Stat tiles, the trend
/// of recent runs, a best per mode, a heat keyboard of the keys you miss, and the leaderboard that comes with accounts.
struct ProgressScreen: View {
    @Environment(\.colorScheme) private var scheme
    private var p: Palette { scheme == .dark ? .dark : .light }
    private let store = DefaultsStore()

    var body: some View {
        let recent = runs(store), misses = savedMisses(store)
        let tests = max(Int(store.get("count") ?? "") ?? 0, recent.count) // older builds counted runs without misses
        let bests = modes.compactMap { m in Int(store.get(m.key) ?? "").map { (m, $0) } }
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: geo.size.width < 520 ? 1 : 3), spacing: 12) { // three tiles share the row
                        tile("Best", bests.map(\.1).max().map { "\($0)" } ?? "–", unit: "wpm")
                        tile(recent.isEmpty ? "Average" : "Average, last \(recent.count)", recent.isEmpty ? "–" : "\(recent.reduce(0, +) / recent.count)", unit: "wpm")
                        tile("Tests", "\(tests)", unit: nil)
                    }
                    section("Recent runs") {
                        Group {
                            if recent.count >= 2 { trend(recent).frame(height: 140) }
                            else { empty("Two runs and your trend shows up here.") }
                        }
                        .padding(20).frame(maxWidth: .infinity).background(p.chip, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    section("Best per mode") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 116), spacing: 12)], spacing: 12) { // all seven modes on one row when wide
                            ForEach(modes.indices, id: \.self) { i in
                                let m = modes[i], v = Int(store.get(m.key) ?? "")
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(m.kind == .time ? "\(m.n) seconds" : m.label).font(.system(size: 13)).foregroundStyle(p.dim)
                                    Text(v.map { "\($0) wpm" } ?? "not yet").font(.system(size: 20, weight: v == nil ? .regular : .semibold))
                                        .foregroundStyle(v == nil ? p.dim : p.text).monospacedDigit()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                                .background(p.chip, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                    }
                    section("Keys you miss") {
                        VStack(spacing: 16) {
                            if misses.isEmpty { empty("Finish a run and the keys you miss light up here.") }
                            else { heat(misses, width: min(geo.size.width - 120, 640)) }
                        }
                        .padding(20).frame(maxWidth: .infinity).background(p.chip, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    section("Leaderboard") {
                        HStack(spacing: 12) {
                            Image(systemName: "trophy").font(.system(size: 20)).foregroundStyle(p.bad)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Daily and weekly boards, per mode").font(.system(size: 15, weight: .semibold)).foregroundStyle(p.text)
                                Text("Coming with synced accounts. Your runs stay on this device until then.").font(.system(size: 13)).foregroundStyle(p.dim)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(20).background(p.chip, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .frame(maxWidth: 960)
                .padding(.horizontal, max(24, geo.size.width * 0.06))
                .padding(.top, 56).padding(.bottom, 104) // clear of the traffic lights and the bottom bar
                .frame(maxWidth: .infinity)
            }
        }
        .background(p.bg.ignoresSafeArea())
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(p.dim).textCase(.uppercase).kerning(0.4)
            content()
        }
    }

    private func tile(_ label: String, _ value: String, unit: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 13)).foregroundStyle(p.dim)
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(value).font(.system(size: 40, weight: .semibold)).foregroundStyle(p.text).monospacedDigit()
                if let unit { Text(unit).font(.system(size: 15)).foregroundStyle(p.dim) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(20)
        .background(p.chip, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func empty(_ text: String) -> some View {
        Text(text).font(.system(size: 14)).foregroundStyle(p.dim).frame(maxWidth: .infinity, minHeight: 60)
    }

    /// The last runs as a line with a soft fill under it; the newest run is a blue dot.
    private func trend(_ r: [Int]) -> some View {
        GeometryReader { g in
            let lo = Double((r.min() ?? 0)) * 0.85, hi = Double(r.max() ?? 1), span = max(hi - lo, 1)
            let pts = r.enumerated().map { i, v in
                CGPoint(x: CGFloat(i) / CGFloat(r.count - 1) * g.size.width, y: g.size.height - CGFloat((Double(v) - lo) / span) * (g.size.height - 8) - 4)
            }
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: g.size.height)); pts.forEach { path.addLine(to: $0) }
                    path.addLine(to: CGPoint(x: g.size.width, y: g.size.height)); path.closeSubpath()
                }
                .fill(LinearGradient(colors: [p.bad.opacity(0.18), p.bad.opacity(0)], startPoint: .top, endPoint: .bottom))
                Path { path in path.move(to: pts[0]); pts.dropFirst().forEach { path.addLine(to: $0) } }
                    .stroke(p.text, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                Circle().fill(p.bad).frame(width: 9, height: 9).position(pts.last!)
            }
        }
        .accessibilityElement().accessibilityLabel("Words per minute over your last \(r.count) runs, latest \(r.last ?? 0)")
    }

    /// Every letter key, shaded by how often you miss it; the five worst are solid blue.
    private func heat(_ misses: [String: Int], width: CGFloat) -> some View {
        let most = Double(misses.values.max() ?? 1), worst = Set(misses.sorted { $0.value > $1.value }.prefix(5).map(\.key))
        let k = min(max((width - 9 * 6) / 10, 28), 52)
        return VStack(spacing: 6) {
            ForEach(Array(["qwertyuiop", "asdfghjkl", "zxcvbnm"].enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row.map(String.init), id: \.self) { key in
                        let n = misses[key] ?? 0, hot = worst.contains(key)
                        Text(key).font(.system(size: k * 0.38, weight: hot ? .semibold : .regular))
                            .foregroundStyle(hot ? Color.white : n > 0 ? p.text : p.dim)
                            .frame(width: k, height: k)
                            .background(hot ? p.bad : p.bad.opacity(n > 0 ? 0.1 + 0.35 * Double(n) / most : 0), in: RoundedRectangle(cornerRadius: k * 0.18, style: .continuous))
                            .background(p.bg, in: RoundedRectangle(cornerRadius: k * 0.18, style: .continuous))
                    }
                }
            }
            Text(worst.isEmpty ? "" : "Missed most: " + misses.sorted { $0.value > $1.value }.prefix(5).map { "\($0.key) \($0.value)×" }.joined(separator: "  ·  "))
                .font(.system(size: 13)).foregroundStyle(p.dim).padding(.top, 6)
        }
        .accessibilityElement().accessibilityLabel("Keys you miss most: " + misses.sorted { $0.value > $1.value }.prefix(5).map(\.key).joined(separator: ", "))
    }
}
