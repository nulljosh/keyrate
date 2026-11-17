import SwiftUI

/// The window: the test, or your progress, picked from a bar at the bottom.
struct RootView: View {
    enum Tab { case test, progress }
    @State private var tab = Tab.test

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case .test: ContentView()
                case .progress: ScrollView { ProgressPane().frame(maxWidth: 560) }.frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            HStack(spacing: 4) {
                item("Test", "keyboard", .test)
                item("Progress", "chart.line.uptrend.xyaxis", .progress)
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(.bar)
        }
    }

    private func item(_ title: String, _ icon: String, _ t: Tab) -> some View {
        Button { tab = t } label: {
            Label(title, systemImage: icon).font(.system(size: 13, weight: tab == t ? .semibold : .regular))
                .foregroundStyle(tab == t ? .primary : .secondary)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(tab == t ? Color.primary.opacity(0.08) : .clear, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(t == .test ? "1" : "2", modifiers: [.command, .option])
    }
}
