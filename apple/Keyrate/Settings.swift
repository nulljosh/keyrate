import SwiftUI

/// The Mac Settings window (Cmd-,): appearance, and your progress from what this device has saved.
struct SettingsView: View {
    @AppStorage("appearance") private var appearance = Appearance.system

    var body: some View {
        TabView {
            Form {
                Picker("Appearance", selection: $appearance) {
                    ForEach(Appearance.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.inline)
            }
            .padding(24)
            .tabItem { Label("General", systemImage: "gearshape") }

            ProgressPane()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .frame(width: 480)
        .preferredColorScheme(appearance.scheme)
    }
}

/// Bests per mode, the last runs, and the keys you miss most. Everything stays on this device.
struct ProgressPane: View {
    private let store = DefaultsStore()

    var body: some View {
        let recent = runs(store), weak = savedMisses(store).sorted { $0.value > $1.value }.prefix(5)
        VStack(alignment: .leading, spacing: 20) {
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 8) {
                ForEach(modes.indices, id: \.self) { i in
                    GridRow {
                        Text(modes[i].kind == .time ? "\(modes[i].n) seconds" : modes[i].label).foregroundStyle(.secondary)
                        Text(store.get(modes[i].key).map { "\($0) wpm" } ?? "not yet").monospacedDigit()
                    }
                }
            }
            Divider()
            HStack(spacing: 32) {
                stat("Tests", store.get("count") ?? "\(recent.count)")
                stat("Average, last \(recent.count)", recent.isEmpty ? "—" : "\(recent.reduce(0, +) / recent.count) wpm")
            }
            if !weak.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Keys you miss most").foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        ForEach(Array(weak), id: \.key) { k in
                            Text(k.key).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(Color(red: 0.843, green: 0, blue: 0.082), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(size: 22, weight: .semibold)).monospacedDigit()
        }
    }
}
