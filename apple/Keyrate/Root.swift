import SwiftUI

/// The window: the test, your progress or settings (appearance and account), picked from a floating bar at the bottom. The bar is the functional layer,
/// so it gets the same glass as the mode bar (Liquid Glass on macOS 26, the regular material before) and the content
/// scrolls under it. Content itself never gets glass.
struct RootView: View {
    enum Tab { case test, progress, settings }
    /// `open Keyrate.app --args -openTab settings` (or progress) starts on that tab, for QA screenshots.
    @State private var tab: Tab = { switch UserDefaults.standard.string(forKey: "openTab") { case "settings": .settings; case "progress": .progress; default: .test } }()

    var body: some View {
        Group {
            switch tab {
            case .test: ContentView()
            case .progress: ProgressScreen()
            case .settings: SettingsScreen()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 2) {
                item("Test", "keyboard", .test)
                item("Progress", "chart.line.uptrend.xyaxis", .progress)
                item("Settings", "gearshape", .settings)
            }
            .padding(4) // 4 pt inset: the selected capsule sits concentric inside the bar
            .fixedSize()
            .glassBar()
            .padding(.bottom, 20)
        }
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 560)
        #endif
    }

    private func item(_ title: String, _ icon: String, _ t: Tab) -> some View {
        Button { tab = t } label: {
            Label(title, systemImage: icon).font(.system(.footnote, weight: tab == t ? .semibold : .regular))
                .foregroundStyle(tab == t ? .primary : .secondary)
                .padding(.horizontal, 16).frame(minHeight: 36)
                .background(tab == t ? Color.primary.opacity(0.08) : .clear, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(t == .test ? "1" : t == .progress ? "2" : "3", modifiers: [.command, .option])
        .accessibilityAddTraits(tab == t ? .isSelected : [])
    }
}
