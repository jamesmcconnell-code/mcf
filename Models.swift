import Foundation
import SwiftUI

enum TransactionKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case expense, paycheck, income, balanceAdjustment
    var id: String { rawValue }
    var title: String {
        switch self {
        case .expense: "Expense"
        case .paycheck: "Paycheck"
        case .income: "Income"
        case .balanceAdjustment: "Balance adjustment"
        }
    }
    var sign: Int64 { self == .expense ? -1 : 1 }
    func balanceEffect(for amountCents: Int64) -> Int64 { amountCents * sign }
}

struct ExpenseCategory: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    static let defaults: [ExpenseCategory] = [
        .init(name: "Housing", icon: "house.fill"), .init(name: "Groceries", icon: "basket.fill"),
        .init(name: "Restaurants", icon: "fork.knife"), .init(name: "Transportation", icon: "car.fill"),
        .init(name: "Shopping", icon: "bag.fill"), .init(name: "Entertainment", icon: "sparkles.tv.fill"),
        .init(name: "Health", icon: "cross.case.fill"), .init(name: "Utilities", icon: "bolt.fill"),
        .init(name: "Subscriptions", icon: "repeat"), .init(name: "Personal", icon: "person.fill"),
        .init(name: "Other", icon: "ellipsis.circle.fill")
    ]
}

struct CashTransaction: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var kind: TransactionKind
    var amountCents: Int64
    var date: Date
    var categoryID: UUID?
    var periodID: UUID?
    var title: String
    var source: String = ""
}

struct CategorySpend: Identifiable {
    var category: ExpenseCategory
    var amountCents: Int64
    var id: UUID { category.id }
}

struct PayPeriod: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var startDate: Date
    var endDate: Date?
    var paycheckTransactionID: UUID
    var isClosed: Bool { endDate != nil }
}

struct LedgerData: Codable {
    var openingBalanceCents: Int64
    var currencyCode: String
    var categories: [ExpenseCategory]
    var transactions: [CashTransaction]
    var periods: [PayPeriod]
    var hasCompletedSetup: Bool
    static let fresh = LedgerData(openingBalanceCents: 0, currencyCode: ["USD", "CAD", "GBP", "EUR", "AUD", "NZD", "CHF"].contains(Locale.current.currency?.identifier ?? "USD") ? (Locale.current.currency?.identifier ?? "USD") : "USD", categories: ExpenseCategory.defaults, transactions: [], periods: [], hasCompletedSetup: false)
}

enum Money {
    static func cents(from input: String) -> Int64? {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "")
        guard let decimal = Decimal(string: value) else { return nil }
        var scaled = decimal * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        return NSDecimalNumber(decimal: rounded).int64Value
    }
    static func string(_ cents: Int64, currency: String) -> String {
        let amount = Decimal(cents) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency) \(amount)"
    }
    static func input(_ cents: Int64) -> String {
        let magnitude = cents == Int64.min ? Int64.max : abs(cents)
        return "\(cents < 0 ? "-" : "")\(magnitude / 100).\(String(format: "%02lld", magnitude % 100))"
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
}
