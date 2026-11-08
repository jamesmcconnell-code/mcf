import LocalAuthentication
import SwiftUI

@MainActor
final class AppLockManager: ObservableObject {
    private let preferenceKey = "requireDeviceAuthentication"
    @Published private(set) var isEnabled: Bool
    @Published private(set) var isUnlocked: Bool
    @Published private(set) var isAuthenticating = false
    @Published private(set) var errorMessage: String?

    init() {
        let enabled = UserDefaults.standard.bool(forKey: preferenceKey)
        isEnabled = enabled
        isUnlocked = !enabled
    }

    func enable() async -> Bool {
        guard await authenticate() else { return false }
        UserDefaults.standard.set(true, forKey: preferenceKey)
        isEnabled = true
        isUnlocked = true
        return true
    }

    func disable() {
        UserDefaults.standard.set(false, forKey: preferenceKey)
        isEnabled = false
        isUnlocked = true
        errorMessage = nil
    }

    func lockForBackground() {
        guard isEnabled else { return }
        isUnlocked = false
        errorMessage = nil
    }

    func unlock() async {
        guard isEnabled, !isUnlocked, !isAuthenticating else { return }
        _ = await authenticate()
    }

    private func authenticate() async -> Bool {
        guard !isAuthenticating else { return false }
        let context = LAContext()
        var availabilityError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &availabilityError) else {
            errorMessage = "Set a device passcode in Settings to use app lock."
            return false
        }

        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock your cash flow information.")
            isUnlocked = true
            errorMessage = nil
            return true
        } catch let error as LAError where error.code == .userCancel || error.code == .systemCancel || error.code == .appCancel {
            errorMessage = nil
            return false
        } catch {
            errorMessage = "Authentication didn’t complete. Try again."
            return false
        }
    }
}

struct AppLockScreen: View {
    @EnvironmentObject private var appLock: AppLockManager

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.fill")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(Color(hex: 0x286B58))
                .frame(width: 86, height: 86)
                .background(Color(hex: 0xE8F2ED), in: Circle())
            Text("Cash Flow is locked")
                .font(.title2.bold())
            Text("Unlock to view your financial information.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let errorMessage = appLock.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                Task { await appLock.unlock() }
            } label: {
                Label("Unlock with Face ID or passcode", systemImage: "faceid")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(15)
            }
            .buttonStyle(.borderedProminent)
            .disabled(appLock.isAuthenticating)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: 0xF6F7F5).ignoresSafeArea())
    }
}
