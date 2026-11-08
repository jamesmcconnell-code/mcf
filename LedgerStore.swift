import Foundation
import SwiftUI

@MainActor
final class LedgerStore: ObservableObject {
    @Published private(set) var data: LedgerData
    private let fileURL: URL

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("cash-flow-ledger.json")
        if let saved = try? Data(contentsOf: fileURL), let decoded = try? JSONDecoder().decode(LedgerData.self, from: saved) { data = decoded }
        else { data = .fresh }
    }

    var activePeriod: PayPeriod? { data.periods.first(where: { !$0.isClosed }) }
    var activeTransactions: [CashTransaction] {
        guard let activePeriod else { return [] }
        return data.transactions.filter { $0.periodID == activePeriod.id }
    }
    var balanceCents: Int64 { data.transactions.reduce(data.openingBalanceCents) { $0 + $1.kind.balanceEffect(for: $1.amountCents) } }
    var currentPaycheckCents: Int64 { activeTransactions.filter { $0.kind == .paycheck }.reduce(0) { $0 + $1.amountCents } }
    var additionalIncomeCents: Int64 { activeTransactions.filter { $0.kind == .income }.reduce(0) { $0 + $1.amountCents } }
    var currentIncomeCents: Int64 { currentPaycheckCents + additionalIncomeCents }
    var currentExpensesCents: Int64 { activeTransactions.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amountCents } }
    var currentNetCents: Int64 { currentIncomeCents - currentExpensesCents }

    func saveSetup(openingCents: Int64, currency: String) {
        data.openingBalanceCents = openingCents
        data.currencyCode = currency
        data.hasCompletedSetup = true
        persist()
    }
    func addPeriod(paycheckCents: Int64, date: Date, source: String = "Paycheck") {
        if let index = data.periods.firstIndex(where: { !$0.isClosed }) { data.periods[index].endDate = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date }
        let period = PayPeriod(startDate: date, paycheckTransactionID: UUID())
        let transaction = CashTransaction(id: period.paycheckTransactionID, kind: .paycheck, amountCents: paycheckCents, date: date, categoryID: nil, periodID: period.id, title: source.isEmpty ? "Paycheck" : source, source: source)
        data.periods.append(period)
        data.transactions.append(transaction)
        persist()
    }
    func addExpense(amountCents: Int64, categoryID: UUID, title: String, date: Date) {
        data.transactions.append(CashTransaction(kind: .expense, amountCents: amountCents, date: date, categoryID: categoryID, periodID: activePeriod?.id, title: title.isEmpty ? categoryName(categoryID) : title))
        persist()
    }
    func addIncome(amountCents: Int64, source: String, title: String, date: Date) {
        data.transactions.append(CashTransaction(kind: .income, amountCents: amountCents, date: date, categoryID: nil, periodID: activePeriod?.id, title: title.isEmpty ? source : title, source: source))
        persist()
    }
    func addBalanceAdjustment(amountCents: Int64, title: String, date: Date) {
        data.transactions.append(CashTransaction(kind: .balanceAdjustment, amountCents: amountCents, date: date, categoryID: nil, periodID: activePeriod?.id, title: title.isEmpty ? "Balance adjustment" : title))
        persist()
    }
    func update(_ transaction: CashTransaction) {
        guard let index = data.transactions.firstIndex(where: { $0.id == transaction.id }) else { return }
        data.transactions[index] = transaction
        if transaction.kind == .paycheck, let periodIndex = data.periods.firstIndex(where: { $0.paycheckTransactionID == transaction.id }) {
            data.periods[periodIndex].startDate = transaction.date
            let previousPeriod = data.periods.indices
                .filter { $0 != periodIndex && data.periods[$0].startDate < transaction.date }
                .max { data.periods[$0].startDate < data.periods[$1].startDate }
            if let previousPeriod {
                data.periods[previousPeriod].endDate = Calendar.current.date(byAdding: .day, value: -1, to: transaction.date) ?? transaction.date
            }
        }
        persist()
    }
    func delete(_ transaction: CashTransaction) {
        data.transactions.removeAll { $0.id == transaction.id }
        persist()
    }
    func addCategory(name: String, icon: String) {
        data.categories.append(ExpenseCategory(name: name, icon: icon))
        persist()
    }
    func updateCategory(_ category: ExpenseCategory) {
        guard let index = data.categories.firstIndex(where: { $0.id == category.id }) else { return }
        data.categories[index] = category
        persist()
    }
    func deleteCategory(_ category: ExpenseCategory, reassignTo: UUID) {
        for index in data.transactions.indices where data.transactions[index].categoryID == category.id { data.transactions[index].categoryID = reassignTo }
        data.categories.removeAll { $0.id == category.id }
        persist()
    }
    func resetAllData() { data = .fresh; persist() }
    func categoryName(_ id: UUID?) -> String { data.categories.first(where: { $0.id == id })?.name ?? "Uncategorized" }
    func exportURL() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Cash-Flow-Backup-\(Date.now.formatted(.iso8601.year().month().day())).json")
        try JSONEncoder.pretty.encode(data).write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }
    func periodStartingCash(_ period: PayPeriod) -> Int64 {
        data.openingBalanceCents + data.transactions.filter { $0.date < period.startDate }.reduce(0) { $0 + $1.kind.balanceEffect(for: $1.amountCents) }
    }
    func periodEndingCash(_ period: PayPeriod) -> Int64 {
        guard let end = period.endDate else { return balanceCents }
        return data.openingBalanceCents + data.transactions.filter { $0.date <= end }.reduce(0) { $0 + $1.kind.balanceEffect(for: $1.amountCents) }
    }
    func periodTransactions(_ period: PayPeriod) -> [CashTransaction] { data.transactions.filter { $0.periodID == period.id } }
    private func persist() {
        do { try JSONEncoder.pretty.encode(data).write(to: fileURL, options: [.atomic, .completeFileProtection]) }
        catch { assertionFailure("Unable to save local ledger: \(error)") }
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder { let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; return encoder }
}
