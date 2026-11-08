import SwiftUI

@main
struct MCFApp: App {
    @StateObject private var ledger = LedgerStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(ledger)
                .tint(Color(red: 0.157, green: 0.42, blue: 0.345))
        }
    }
}
