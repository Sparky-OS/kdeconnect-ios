// SPDX-License-Identifier: GPL-3.0-only
#if !os(macOS)
import SwiftUI

struct VirtualMonitorView: View {
    @ObservedObject var plugin: VirtualMonitor
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var missingReceiver = false

    private var statusKey: LocalizedStringKey {
        switch plugin.availability {
        case .available: return "vm_ready"
        case .unavailable: return "vm_unavailable"
        case .untrusted: return "vm_untrusted"
        case .invalid: return "vm_invalid"
        case .timedOut: return "vm_timeout"
        default: return "vm_waiting"
        }
    }
    var body: some View {
        Section {
            Text(statusKey, tableName: "VirtualMonitor")
            Text("vm_pair_separately", tableName: "VirtualMonitor").font(.footnote)
            Button { plugin.refresh() } label: { Text("vm_refresh", tableName: "VirtualMonitor") }
            Button {
                guard plugin.canOpenReceiver() else { plugin.suspend(); return }
                // A fixed launch command only. No peer identity, pin, password or session is exported.
                openURL(URL(string: "flatheadset://catch")!) { accepted in
                    missingReceiver = !accepted
                }
            } label: { Text("vm_catch", tableName: "VirtualMonitor") }
            .disabled(plugin.availability != .available)
        } header: { Text("vm_title", tableName: "VirtualMonitor") }
        .onAppear { plugin.refresh() }
        .onDisappear { plugin.suspend() }
        .onChange(of: scenePhase) { phase in
            if phase == .active { plugin.refresh() } else { plugin.suspend() }
        }
        .alert(Text("vm_title", tableName: "VirtualMonitor"), isPresented: $missingReceiver) {
            Button(role: .cancel) {} label: { Text("vm_back", tableName: "VirtualMonitor") }
        } message: { Text("vm_missing", tableName: "VirtualMonitor") }
    }
}
#endif
