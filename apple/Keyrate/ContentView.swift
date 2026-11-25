import SwiftUI

struct Palette {
    // dim is small text (4.5:1 needed), word is the large upcoming words (3:1 needed)
    let bg, text, dim, word, chip, bad, hi: Color
    // Colours from web/palette.css: white and cool greys in light, near-black and cool greys in dark, blue only for a
    // miss. Never the warm paper or brown-black the shared jaybulb tokens use.
    static let ink = Color(red: 0.114, green: 0.114, blue: 0.122)   // #1d1d1f
    static let snow = Color(red: 0.961, green: 0.961, blue: 0.969)  // #f5f5f7
    static let light = Palette(bg: .white, text: ink, dim: ink.opacity(0.66), word: ink.opacity(0.52), chip: snow,
                               bad: Color(red: 0, green: 0.478, blue: 1), hi: ink.opacity(0.12))
    static let dark = Palette(bg: Color(red: 0.043, green: 0.043, blue: 0.047), text: snow, dim: snow.opacity(0.66), word: snow.opacity(0.52),
                              chip: Color(red: 0.110, green: 0.110, blue: 0.118), bad: Color(red: 0.039, green: 0.518, blue: 1), hi: snow.opacity(0.16))
}

struct DefaultsStore: Store {
    func get(_ key: String) -> String? { UserDefaults.standard.string(forKey: key) }
    func put(_ key: String, _ value: String) { UserDefaults.standard.set(value, forKey: key) }
}



struct ContentView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("appearance") private var appearance = Appearance.system
    @State private var mode = modes[2]
    @State private var punct = false
    @State private var session = Session(mode: modes[2])
    @State private var input = ""
    @State private var best = 0
    @State private var lastQuote: String?
    @State private var clock = 0 // bumped on every tick so the countdown redraws
    @FocusState private var focus: Bool
    private let store = DefaultsStore()
    @Environment(\.scenePhase) private var phase
    /// The countdown ticks only during a run in a window on screen; nothing runs in the background.
    private var ticking: Bool { session.started && !session.done && phase == .active }

    private var p: Palette { scheme == .dark ? .dark : .light }
    /// Follows Dynamic Type (and the Mac's text size), capped so three lines of words still fit the window.
    @ScaledMetric(relativeTo: .title2) private var typeScale: CGFloat = 1
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    /// iPad (regular width) fills the 832 point column with Mac sized words; iPhone keeps them smaller.
    private var wordSize: CGFloat { (sizeClass == .regular ? 28 : 22) * min(typeScale, 1.6) }
    #else
    /// Words grow with the window: 22 pt in a small window up to 40 pt on a big screen, times the text size setting.
    private var wordSize: CGFloat { min(max(area.width / 36, 22), 40) * min(typeScale, 1.6) }
    #endif
    /// The window's content size, measured below, so the test scales and centres in any window.
    @State private var area = CGSize(width: 980, height: 720)
    /// Tab and Return work everywhere except iOS 16, where only the restart chip does.
    private var keyHints: Bool {
        #if os(iOS)
        if #available(iOS 17, *) { return true } else { return false }
        #else
        return true
        #endif
    }
    private var nowMs: Int64 { Int64(ProcessInfo.processInfo.systemUptime * 1000) + 1 } // never 0, Session reads 0 as "not started"

    /// The splash plays once, on the very first launch. After an update, a What's New sheet shows once instead.
    private static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    private static let seen = UserDefaults.standard.string(forKey: "seenVersion")
    @State private var splash = seen == nil && UserDefaults.standard.string(forKey: "shot") == nil // store shots skip it
    @State private var whatsNew = seen != nil && seen != version

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(counter).font(.title3).foregroundStyle(p.dim).monospacedDigit()
                wordsView
                TextField("", text: $input)
                    .textFieldStyle(.plain)
                    .focused($focus)
                    .frame(width: 1, height: 1).opacity(0.01)
                    .foregroundStyle(.clear).tint(.clear) // no stray caret dot under the words
                    .accessibilityLabel("Type the words shown")
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .onChange(of: input) { new in
                        if new != session.text { session.setText(new, nowMs: nowMs) }
                        if input != session.text { input = session.text } // a refused edit puts the old text back
                        clock += 1
                    }
                    .modifier(KeyHandlers(tab: { restart() }, enter: { if session.done { restart(); return true }; return false }))
                if let r = session.result { resultView(r) } else {
                    Text(keyHints ? "Start typing. Tab restarts." : "Start typing.").font(.subheadline).foregroundStyle(p.dim)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: max(area.height - 72, 400)) // centred in the window, clear of the bars
        }
        .safeAreaInset(edge: .top) { // functional layer: the only glass. A compact centred pill on the Mac, as on the web
            #if os(macOS)
            modeBar.padding(4).fixedSize().glassBar().frame(maxWidth: .infinity).padding(.top, 20)
            #else
            modeBar.padding(6).glassBar().padding(.horizontal, 16).padding(.top, 8)
            #endif
        }
        .background(GeometryReader { g in Color.clear.onAppear { area = g.size }.onChange(of: g.size) { area = $0 } })
        .background(p.bg.ignoresSafeArea())
        .overlay { if splash { Splash(shown: $splash, bg: p.bg) } }
        .onAppear { UserDefaults.standard.set(Self.version, forKey: "seenVersion") }
        .sheet(isPresented: $whatsNew) { WhatsNew(version: Self.version) }
        .task { try? await Task.sleep(for: .milliseconds(300)); focus = true } // the field is not focusable until the window is up
        #if DEBUG
        .onAppear(perform: shot)
        #endif
        .task(id: ticking) {
            while ticking, !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                session.tick(nowMs: nowMs); clock += 1
            }
        }
        .onChange(of: session.done) { done in
            if done, let r = session.result {
                best = session.pasted ? Int(store.get(mode.key) ?? "") ?? 0 : recordRun(store, mode, r.wpm)
                if !session.pasted { addMisses(store, session.misses) }
            }
        }
    }

    private var counter: String {
        _ = clock
        if session.done { return session.elapsed }
        if mode.kind == .time { return String(session.remaining(nowMs: nowMs)) }
        return "\(min(session.typed.count - 1, session.total))/\(session.total)"
    }

    private var wordsView: some View {
        Flow(hSpacing: wordSize * 0.3, vSpacing: wordSize * 0.35, window: (session.typed.count - 1, 3)) {
            ForEach(session.target.indices, id: \.self) { k in
                Text(attributed(k)).font(.system(size: wordSize)).fixedSize()
            }
        }
        .frame(maxWidth: min(max(area.width * 0.82, 320), 1200))
        .clipped()
        .opacity(session.done || !focus ? 0.35 : 1)
        .contentShape(Rectangle())
        .onTapGesture { focus = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Words to type")
    }

    private func attributed(_ k: Int) -> AttributedString {
        let t = Array(session.target[k])
        let ty = k < session.typed.count ? Array(session.typed[k]) : []
        let cur = session.typed.count - 1
        let wrongDone = k < cur && ty != t
        var out = AttributedString()
        for c in 0..<max(t.count, ty.count) {
            var s = AttributedString(String(c >= t.count ? ty[c] : t[c]))
            s.foregroundColor = c >= t.count ? p.bad.opacity(0.6) : c < ty.count ? (ty[c] == t[c] ? p.text : p.bad) : p.word
            if wrongDone { s.underlineStyle = .single }
            if k == cur && c == ty.count { s.backgroundColor = p.hi }
            out += s
        }
        if k == cur && ty.count >= t.count { // the space after the word is where the caret sits once it is complete
            var s = AttributedString(" ")
            s.backgroundColor = p.hi
            out += s
        }
        return out
    }

    /// One row on the Mac (the window is always wide enough); wraps on a phone.
    @ViewBuilder private var modeBar: some View {
        #if os(macOS)
        HStack(spacing: 4) { barItems }
        #else
        Flow(hSpacing: 4, vSpacing: 4, centered: true) { barItems }
        #endif
    }

    @ViewBuilder private var barItems: some View {
        Group {
            ForEach(modes.indices, id: \.self) { i in
                chip(modes[i].label, on: modes[i] == mode) { mode = modes[i]; restart() }
                    .keyboardShortcut(KeyEquivalent(Character("\(i + 1)")), modifiers: .command) // Cmd-1 to Cmd-6
                if i == 2 || i == modes.count - 1 { divider } // time | words and quote | toggles, as on the web
            }
            chip("punct", on: punct) { punct.toggle(); restart() }
            chip("restart", on: false) { restart() }
                .keyboardShortcut("r", modifiers: .command)
            // One click cycles auto, light, dark, as on the web (a Picker in a Menu showed an empty submenu on macOS 13)
            Button {
                let all = Appearance.allCases
                appearance = all[(all.firstIndex(of: appearance)! + 1) % all.count]
            } label: {
                Label(appearance == .system ? "auto" : appearance.rawValue, systemImage: "circle.lefthalf.filled")
                    .labelStyle(.titleAndIcon).font(.subheadline).foregroundStyle(p.dim)
                    .padding(.horizontal, 14).frame(minHeight: 36).contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .help("Appearance: auto follows your device")
            .accessibilityLabel("Appearance, \(appearance == .system ? "auto" : appearance.rawValue)")
        }
    }

    private var divider: some View {
        Text("|").font(.subheadline).foregroundStyle(p.dim.opacity(0.5)).padding(.vertical, 8).accessibilityHidden(true)
    }

    private func chip(_ label: String, on: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.subheadline).foregroundStyle(on ? p.text : p.dim)
                .padding(.horizontal, 14).frame(minHeight: 36)
                .background(on ? p.chip : .clear, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func resultView(_ r: Stats) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(r.wpm)").font(.system(size: wordSize * 2.5, weight: .semibold)).foregroundStyle(p.text)
                Text("wpm").font(.callout).foregroundStyle(p.dim)
            }
            HStack(spacing: 24) {
                stat("accuracy", "\(r.accuracy)%")
                stat("keys", "\(session.keyAccuracy)%")
                stat("raw", "\(r.raw)")
                stat("chars", "\(r.correct)/\(r.wrong)")
                stat("consistency", "\(session.consistency)%")
            }
            sparkline(session.curve, height: 64, floor: Int(Double(session.curve.min() ?? 0) * 0.8)).accessibilityLabel("Words per minute over the run")
            keyboard(topMisses(session.misses))
            Text("best \(best) wpm · \(mode.kind == .time ? "\(mode.n)s" : mode.label)").font(.subheadline).foregroundStyle(p.dim)
            sparkline(runs(store))
            if keyHints { Text("Enter restarts.").font(.footnote).foregroundStyle(p.dim) }
        }
        .accessibilityElement(children: .combine)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption).foregroundStyle(p.dim)
            Text(value).font(.title3).foregroundStyle(p.text)
        }
    }

    /// The result keyboard: the five keys missed most lit, the count in words below it. Letters and the space bar are
    /// drawn; a missed comma or digit only shows in the line.
    private func keyboard(_ top: [(key: String, count: Int)]) -> some View {
        let lit = Set(top.map(\.key))
        return VStack(spacing: 8) {
            if !top.isEmpty {
                VStack(spacing: 3) {
                    ForEach(keyRows, id: \.self) { row in
                        HStack(spacing: 3) {
                            ForEach(row.map(String.init), id: \.self) { k in
                                Text(k == " " ? "space" : k)
                                    .font(.system(size: 14, weight: lit.contains(k) ? .semibold : .regular))
                                    .foregroundStyle(lit.contains(k) ? .white : p.dim)
                                    .frame(width: k == " " ? 160 : 30, height: 30)
                                    .background(lit.contains(k) ? p.bad : p.chip, in: RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
                .accessibilityHidden(true)
            }
            Text(missedLine(top)).font(.subheadline).foregroundStyle(p.dim)
        }
    }

    /// A line through the values. `floor` lifts the bottom of the scale off zero, so a run's small swings show.
    @ViewBuilder private func sparkline(_ r: [Int], height: CGFloat = 40, floor: Int = 0) -> some View {
        if r.count >= 2 {
            let top = CGFloat(max((r.max() ?? 1) - floor, 1))
            Path { path in
                for (i, v) in r.enumerated() {
                    let pt = CGPoint(x: 2 + CGFloat(i) / CGFloat(r.count - 1) * 236, y: height - 2 - CGFloat(v - floor) / top * (height - 4))
                    i == 0 ? path.move(to: pt) : path.addLine(to: pt)
                }
            }
            .stroke(p.text, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            .frame(width: 240, height: height)
        }
    }

    #if DEBUG
    /// Store screenshots without a demo account or a hand on the keyboard: `-shot typing` stops seven words into a
    /// 25 word run, `-shot result` finishes it. The run is typed one character at a time at about 85 wpm, with a few
    /// typos fixed, through the same setText the keyboard uses.
    private func shot() {
        guard let kind = UserDefaults.standard.string(forKey: "shot") else { return }
        #if os(macOS)
        NSApp.windows.first?.setFrame(NSRect(x: 0, y: 0, width: 1440, height: 900), display: true) // 2880x1800 store size at 2x
        #endif
        mode = modes[3]
        session = Session(mode: mode, dice: .seeded(4))
        var text = "", ms: Int64 = 1
        func type(_ s: String) { for ch in s { text.append(ch); ms += 140; session.setText(text, nowMs: ms) } }
        func erase() { text.removeLast(); ms += 140; session.setText(text, nowMs: ms) }
        let count = kind == "result" ? session.target.count : 7
        for (i, w) in session.target.prefix(count).enumerated() {
            if i % 4 == 2, let first = w.first { type(first == "e" ? "r" : "e"); erase() } // a slip, fixed: the keyboard lights the key
            type(w)
            if i < count - 1 || kind != "result" { type(" ") }
        }
        input = session.text
        // The result reads better without the keyboard over it; the launch task focuses the field at 300 ms.
        if kind == "result" { Task { try? await Task.sleep(for: .milliseconds(800)); focus = false } }
    }
    #endif

    private func restart() {
        // drill: words built from the five keys you miss most on this device
        let weak = savedMisses(store).sorted { $0.value > $1.value }.prefix(5).map(\.key)
        session = Session(mode: mode, punct: punct, avoid: lastQuote, pool: mode.kind == .drill ? drillPool(words, weak: weak) : nil)
        if mode.kind == .quote { lastQuote = session.target.joined(separator: " ") }
        input = ""
        best = 0
        focus = true
    }
}

extension View {
    /// Liquid Glass on iOS and macOS 26, the regular material before that.
    @ViewBuilder func glassBar() -> some View {
        // Liquid Glass needs the iOS 26 SDK (Xcode 26); older toolchains build the material fallback only.
        #if compiler(>=6.2)
        if #available(iOS 26, macOS 26, *) { glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24)) } else { background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous)) }
        #else
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        #endif
    }
}

/// Tab restarts, Return restarts after a result. onKeyPress needs macOS 14 / iOS 17; on macOS 13 an AppKit key
/// monitor does the same job. iOS 16 relies on the restart chip (a hardware keyboard there is rare).
private struct KeyHandlers: ViewModifier {
    let tab: () -> Void
    let enter: () -> Bool
    func body(content: Content) -> some View {
        if #available(iOS 17, macOS 14, *) {
            content
                .onKeyPress(.tab) { tab(); return .handled }
                .onKeyPress(.return) { enter() ? .handled : .ignored }
        } else {
            #if os(macOS)
            content.background(KeyMonitor(tab: tab, enter: enter))
            #else
            content
            #endif
        }
    }
}

#if os(macOS)
import AppKit
private struct KeyMonitor: NSViewRepresentable {
    let tab: () -> Void
    let enter: () -> Bool
    /// Holds the latest closures and the view, so the monitor acts only for its own window (not Settings or a
    /// second test window) and never on a stale copy of the closures.
    final class Coordinator { var monitor: Any?; weak var view: NSView?; var tab: () -> Void = {}; var enter: () -> Bool = { false } }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context: Context) -> NSView {
        let v = NSView(), c = context.coordinator
        c.view = v; c.tab = tab; c.enter = enter
        c.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak c] e in
            guard let c, let w = c.view?.window, e.window === w else { return e }
            let plain = e.modifierFlags.intersection([.shift, .command, .option, .control]).isEmpty
            switch e.keyCode {
            case 48 where plain: c.tab(); return nil          // Tab
            case 36, 76: return c.enter() ? nil : e           // Return, keypad Enter
            default: return e
            }
        }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) { context.coordinator.tab = tab; context.coordinator.enter = enter }
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        if let m = coordinator.monitor { NSEvent.removeMonitor(m) }
    }
}
#endif

/// Shown once after an update. Plain, like Apple's own: a title, three lines, one button.
struct WhatsNew: View {
    let version: String
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What's new in Keyrate \(version)").font(.system(.title2, weight: .bold))
            item("scope", "Drill mode", "25 words built from the keys you miss most.")
            item("person.crop.circle", "Settings and an account", "Log in with Apple or email. Pick light, dark or auto.")
            item("chart.line.uptrend.xyaxis", "A new Progress tab", "Your bests, your trend and a heat map of the keys you miss.")
            Button("Continue") { dismiss() }.keyboardShortcut(.defaultAction).frame(maxWidth: .infinity)
        }
        .padding(28).frame(width: 420)
    }
    private func item(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.title3).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) { Text(title).fontWeight(.semibold); Text(body).foregroundStyle(.secondary) }
        }
    }
}
