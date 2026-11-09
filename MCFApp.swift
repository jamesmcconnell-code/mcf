import SwiftUI

@main
struct MCFApp: App {
    @StateObject private var ledger = LedgerStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(ledger)
                .tint(Color(hex: 0x14203D))
        }
    }
}
