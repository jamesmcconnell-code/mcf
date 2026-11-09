import SwiftUI
import Charts

struct RootView: View {
    @EnvironmentObject private var ledger: LedgerStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appLock = AppLockManager()
    @State private var showSetup = false
    @State private var showExpense = false
    @State private var showIncome = false
    @State private var showPeriod = false

    var body: some View {
        ZStack {
            TabView {
                NavigationStack {
                    OverviewView(showExpense: $showExpense, showIncome: $showIncome, showPeriod: $showPeriod)
                }
                .tabItem { Label("Overview", systemImage: "square.grid.2x2.fill") }
                NavigationStack { TransactionsView() }
                    .tabItem { Label("Activity", systemImage: "list.bullet.rectangle") }
                NavigationStack { SpendingView() }
                    .tabItem { Label("Scoops", systemImage: "chart.pie.fill") }
                NavigationStack { PeriodsView() }
                    .tabItem { Label("Periods", systemImage: "calendar") }
                NavigationStack { SettingsView() }
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            if appLock.isEnabled && (!appLock.isUnlocked || scenePhase != .active) {
                AppLockScreen().zIndex(1)
            }
        }
        .environmentObject(appLock)
        .onAppear { showSetup = !ledger.data.hasCompletedSetup }
        .onChange(of: ledger.data.hasCompletedSetup) { _, isComplete in
            if !isComplete { showSetup = true }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .background {
                appLock.lockForBackground()
            } else if phase == .active && appLock.isEnabled && !appLock.isUnlocked {
                Task { await appLock.unlock() }
            }
        }
        .sheet(isPresented: $showSetup) { SetupView() }
        .sheet(isPresented: $showExpense) { TransactionFormView(kind: .expense) }
        .sheet(isPresented: $showIncome) { TransactionFormView(kind: .income) }
        .sheet(isPresented: $showPeriod) { NewPeriodView() }
    }
}

struct OverviewView: View {
    @EnvironmentObject private var ledger: LedgerStore
    @Binding var showExpense: Bool
    @Binding var showIncome: Bool
    @Binding var showPeriod: Bool
    private var recent: [CashTransaction] { Array(ledger.data.transactions.sorted { $0.date > $1.date }.prefix(5)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AVAILABLE CASH").font(.caption.weight(.bold)).tracking(1.3).foregroundStyle(.white.opacity(0.78))
                    Text(Money.string(ledger.balanceCents, currency: ledger.data.currencyCode)).font(.system(size: 38, weight: .bold, design: .rounded)).foregroundStyle(.white).minimumScaleFactor(0.7).lineLimit(1)
                    Label(ledger.activePeriod == nil ? "Ready when you are" : "Scoop money out, carry the rest forward", systemImage: "arrow.right.circle.fill").font(.subheadline).foregroundStyle(.white.opacity(0.82))
                }
                .padding(22).frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [Color(hex: 0x253654), Color(hex: 0x10182D)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 14) {
                    HStack { Text("This pay period").font(.title3.bold()); Spacer(); if let period = ledger.activePeriod { Text(period.startDate.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(.secondary) } }
                    HStack(spacing: 10) {
                        MetricCard(title: "Paycheck", amount: ledger.currentPaycheckCents, currency: ledger.data.currencyCode, icon: "briefcase.fill", tint: Color(hex: 0x14203D))
                        MetricCard(title: "Extra income", amount: ledger.additionalIncomeCents, currency: ledger.data.currencyCode, icon: "plus.circle.fill", tint: Color(hex: 0x43587B))
                    }
                    HStack(spacing: 10) {
                        MetricCard(title: "Total income", amount: ledger.currentIncomeCents, currency: ledger.data.currencyCode, icon: "arrow.down.left", tint: Color(hex: 0x14203D))
                        MetricCard(title: "Scoops out", amount: ledger.currentExpensesCents, currency: ledger.data.currencyCode, icon: "arrow.up.right", tint: Color(hex: 0xD49B4A))
                    }
                    MetricCard(title: "Net remaining", amount: ledger.currentNetCents, currency: ledger.data.currencyCode, icon: "equal.circle.fill", tint: .primary)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick actions").font(.title3.bold())
                    HStack(spacing: 10) {
                        ActionButton(title: "Add a scoop", icon: "minus", color: Color(hex: 0x14203D)) { showExpense = true }
                        ActionButton(title: "Add income", icon: "plus", color: Color(hex: 0x43587B)) { showIncome = true }
                    }
                    Button { showPeriod = true } label: {
                        Label(ledger.activePeriod == nil ? "Start your first pay period" : "Start a new pay period", systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(14)
                            .background(Color(hex: 0xF4EBD5), in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    HStack { Text("Recent activity").font(.title3.bold()); Spacer(); NavigationLink("See all") { TransactionsView() }.font(.subheadline.weight(.semibold)) }
                    if recent.isEmpty { EmptyState(icon: "tray", title: "No transactions yet", message: "Your activity will show up here.") }
                    else { VStack(spacing: 0) { ForEach(recent) { TransactionRow(transaction: $0) ; if $0.id != recent.last?.id { Divider().padding(.leading, 56) } } }.padding(.horizontal, 14).background(.background, in: RoundedRectangle(cornerRadius: 18)) }
                }
            }.padding(18)
        }
        .background(Color(hex: 0xFFFAEF))
        .navigationTitle("Scoops Cash Flow")
    }
}

struct MetricCard: View {
    let title: String; let amount: Int64; let currency: String; let icon: String; let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            Text(Money.string(amount, currency: currency)).font(.system(.headline, design: .rounded).weight(.bold)).lineLimit(1).minimumScaleFactor(0.7)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ActionButton: View {
    let title: String; let icon: String; let color: Color; let action: () -> Void
    var body: some View { Button(action: action) { Label(title, systemImage: icon).font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(14).foregroundStyle(color).background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 14)) } }
}

struct TransactionsView: View {
    @EnvironmentObject private var ledger: LedgerStore
    @State private var search = ""
    @State private var categoryID: UUID?
    @State private var filterByDate = false
    @State private var startDate = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    @State private var endDate = Date()
    @State private var selectedTransaction: CashTransaction?
    @State private var showingExpense = false
    @State private var showingIncome = false
    private var filtered: [CashTransaction] {
        ledger.data.transactions.filter { transaction in
            (categoryID == nil || transaction.categoryID == categoryID) &&
            (!filterByDate || (transaction.date >= Calendar.current.startOfDay(for: startDate) && transaction.date < Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate))!)) &&
            (search.isEmpty || transaction.title.localizedCaseInsensitiveContains(search) || transaction.source.localizedCaseInsensitiveContains(search) || ledger.categoryName(transaction.categoryID).localizedCaseInsensitiveContains(search))
        }.sorted { $0.date > $1.date }
    }
    var body: some View {
        List {
            Section("Filters") {
                Picker("Category", selection: $categoryID) {
                    Text("All categories").tag(UUID?.none)
                    ForEach(ledger.data.categories) { category in Text(category.name).tag(Optional(category.id)) }
                }
                Toggle("Filter by date", isOn: $filterByDate)
                if filterByDate {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("Through", selection: $endDate, displayedComponents: .date)
                }
            }
            if filtered.isEmpty { ContentUnavailableView(search.isEmpty ? "No transactions" : "No matches", systemImage: "magnifyingglass", description: Text("Try another search or add a transaction.")) }
            else {
                ForEach(filtered) { transaction in
                    TransactionRow(transaction: transaction).contentShape(Rectangle()).onTapGesture { selectedTransaction = transaction }
                        .swipeActions { Button(role: .destructive) { ledger.delete(transaction) } label: { Label("Delete", systemImage: "trash") } }
                }
            }
        }
        .searchable(text: $search, prompt: "Search activity")
        .navigationTitle("Activity")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Menu { Button("Expense", systemImage: "minus") { showingExpense = true }; Button("Income", systemImage: "plus") { showingIncome = true } } label: { Image(systemName: "plus.circle.fill") } } }
        .sheet(isPresented: $showingExpense) { TransactionFormView(kind: .expense) }
        .sheet(isPresented: $showingIncome) { TransactionFormView(kind: .income) }
        .sheet(item: $selectedTransaction) { transaction in TransactionFormView(kind: transaction.kind, existing: transaction) }
    }
}

struct TransactionRow: View {
    @EnvironmentObject private var ledger: LedgerStore
    let transaction: CashTransaction
    private var isExpense: Bool { transaction.kind == .expense }
    private var displayedAmount: Int64 { transaction.kind.balanceEffect(for: transaction.amountCents) }
    private var icon: String {
        if isExpense { return ledger.data.categories.first(where: { $0.id == transaction.categoryID })?.icon ?? "circle" }
        if transaction.kind == .paycheck { return "briefcase.fill" }
        if transaction.kind == .balanceAdjustment { return "arrow.left.arrow.right.circle.fill" }
        return "plus.circle.fill"
    }
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(isExpense ? Color(hex: 0xD49B4A) : Color(hex: 0x14203D)).frame(width: 40, height: 40).background((isExpense ? Color(hex: 0xD49B4A) : Color(hex: 0x14203D)).opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text(isExpense ? ledger.categoryName(transaction.categoryID) : transaction.kind.title).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(displayedAmount > 0 ? "+" : "")\(Money.string(displayedAmount, currency: ledger.data.currencyCode))").font(.subheadline.weight(.semibold)).monospacedDigit()
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 5).listRowSeparator(.hidden)
    }
}

struct SpendingView: View {
    @EnvironmentObject private var ledger: LedgerStore
    @State private var useAllHistory = false
    private var expenses: [CashTransaction] { ledger.data.transactions.filter { $0.kind == .expense && (useAllHistory || $0.periodID == ledger.activePeriod?.id) } }
    private var rows: [CategorySpend] {
        ledger.data.categories.compactMap { category in let amount = expenses.filter { $0.categoryID == category.id }.reduce(Int64(0)) { $0 + $1.amountCents }; return amount > 0 ? CategorySpend(category: category, amountCents: amount) : nil }.sorted { $0.amountCents > $1.amountCents }
    }
    private var total: Int64 { rows.reduce(0) { $0 + $1.amountCents } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Range", selection: $useAllHistory) { Text("This period").tag(false); Text("All history").tag(true) }.pickerStyle(.segmented)
                VStack(alignment: .leading, spacing: 5) { Text(useAllHistory ? "All scoops" : "Scoops this period").font(.subheadline).foregroundStyle(.secondary); Text(Money.string(total, currency: ledger.data.currencyCode)).font(.largeTitle.bold()).monospacedDigit() }
                    .padding(18).frame(maxWidth: .infinity, alignment: .leading).background(.background, in: RoundedRectangle(cornerRadius: 20))
                if rows.isEmpty { EmptyState(icon: "chart.pie", title: "Nothing to analyze yet", message: "Your scoops will appear here by category.") }
                else {
                    Chart { ForEach(rows) { row in SectorMark(angle: .value(row.category.name, row.amountCents), innerRadius: .ratio(0.62), angularInset: 2).foregroundStyle(by: .value("Category", row.category.name)) } }
                        .frame(height: 220).padding(10).background(.background, in: RoundedRectangle(cornerRadius: 20))
                    VStack(spacing: 0) {
                        ForEach(rows) { row in
                            NavigationLink { CategoryTransactionsView(category: row.category, useAllHistory: useAllHistory) } label: {
                                HStack(spacing: 12) { Image(systemName: row.category.icon).foregroundStyle(Color(hex: 0x14203D)).frame(width: 34); Text(row.category.name).font(.subheadline.weight(.medium)); Spacer(); VStack(alignment: .trailing, spacing: 3) { Text(Money.string(row.amountCents, currency: ledger.data.currencyCode)).font(.subheadline.weight(.semibold)); Text(total > 0 ? "\(Int((Double(row.amountCents) / Double(total) * 100).rounded()))%" : "0%").font(.caption).foregroundStyle(.secondary) } }
                                    .padding(14).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                            if row.id != rows.last?.id { Divider().padding(.leading, 58) }
                        }
                    }.background(.background, in: RoundedRectangle(cornerRadius: 20))
                }
            }.padding(18)
        }.background(Color(hex: 0xFFFAEF)).navigationTitle("Scoops")
    }
}

struct CategoryTransactionsView: View {
    @EnvironmentObject private var ledger: LedgerStore
    let category: ExpenseCategory
    let useAllHistory: Bool
    private var transactions: [CashTransaction] { ledger.data.transactions.filter { $0.kind == .expense && $0.categoryID == category.id && (useAllHistory || $0.periodID == ledger.activePeriod?.id) }.sorted { $0.date > $1.date } }
    var body: some View { List(transactions) { TransactionRow(transaction: $0) }.navigationTitle(category.name) }
}

struct PeriodsView: View {
    @EnvironmentObject private var ledger: LedgerStore
    @State private var showNewPeriod = false
    var body: some View {
        List {
            if ledger.data.periods.isEmpty { ContentUnavailableView("No pay periods", systemImage: "calendar", description: Text("Start one when you receive your next paycheck.")) }
            ForEach(ledger.data.periods.sorted { $0.startDate > $1.startDate }) { period in
                NavigationLink { PeriodDetailView(period: period) } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack { Text(period.isClosed ? "Pay period" : "Current period").font(.headline); Spacer(); Text(period.isClosed ? "Closed" : "Active").font(.caption.weight(.semibold)).foregroundStyle(period.isClosed ? .secondary : Color(hex: 0x14203D)) }
                        Text(period.startDate.formatted(date: .abbreviated, time: .omitted) + (period.endDate.map { " – " + $0.formatted(date: .abbreviated, time: .omitted) } ?? " – Present")).font(.caption).foregroundStyle(.secondary)
                        let transactions = ledger.periodTransactions(period)
                        let income = transactions.filter { $0.kind == .paycheck || $0.kind == .income }.reduce(Int64(0)) { $0 + $1.amountCents }
                        let expenses = transactions.filter { $0.kind == .expense }.reduce(Int64(0)) { $0 + $1.amountCents }
                        Text("Income \(Money.string(income, currency: ledger.data.currencyCode))  ·  Scooped out \(Money.string(expenses, currency: ledger.data.currencyCode))").font(.caption).lineLimit(1).minimumScaleFactor(0.8)
                    }.padding(.vertical, 5)
                }
            }
        }.navigationTitle("Pay periods").toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showNewPeriod = true } label: { Image(systemName: "plus.circle.fill") } } }.sheet(isPresented: $showNewPeriod) { NewPeriodView() }
    }
}

struct PeriodDetailView: View {
    @EnvironmentObject private var ledger: LedgerStore
    let period: PayPeriod
    private var transactions: [CashTransaction] { ledger.periodTransactions(period).sorted { $0.date > $1.date } }
    private var expenses: [CashTransaction] { transactions.filter { $0.kind == .expense } }
    private var income: [CashTransaction] { transactions.filter { $0.kind == .paycheck || $0.kind == .income } }
    var body: some View {
        List {
            Section("Period summary") {
                LabeledContent("Starting available cash", value: Money.string(ledger.periodStartingCash(period), currency: ledger.data.currencyCode))
                LabeledContent("Paycheck", value: Money.string(income.filter { $0.kind == .paycheck }.reduce(0) { $0 + $1.amountCents }, currency: ledger.data.currencyCode))
                LabeledContent("Additional income", value: Money.string(income.filter { $0.kind == .income }.reduce(0) { $0 + $1.amountCents }, currency: ledger.data.currencyCode))
                LabeledContent("Scoops out", value: Money.string(expenses.reduce(0) { $0 + $1.amountCents }, currency: ledger.data.currencyCode))
                LabeledContent("Ending available cash", value: Money.string(ledger.periodEndingCash(period), currency: ledger.data.currencyCode))
            }
            Section("Scoops by category") {
                ForEach(ledger.data.categories) { category in
                    let amount = expenses.filter { $0.categoryID == category.id }.reduce(Int64(0)) { $0 + $1.amountCents }
                    if amount > 0 { LabeledContent(category.name, value: Money.string(amount, currency: ledger.data.currencyCode)) }
                }
            }
            Section("Transactions") { ForEach(transactions) { TransactionRow(transaction: $0) } }
        }.navigationTitle("Period details")
    }
}

struct SettingsView: View {
    @EnvironmentObject private var ledger: LedgerStore
    @EnvironmentObject private var appLock: AppLockManager
    @State private var showCategories = false
    @State private var showBalanceAdjustment = false
    @State private var exportURL: URL?
    @State private var exportError = false
    @State private var confirmDeleteAll = false
    @State private var showLockError = false
    var body: some View {
        List {
            Section("Preferences") {
                NavigationLink { CurrencyView() } label: { LabeledContent("Currency", value: ledger.data.currencyCode) }
                LabeledContent("Original opening cash", value: Money.string(ledger.data.openingBalanceCents, currency: ledger.data.currencyCode))
                Button { showBalanceAdjustment = true } label: { Label("Record balance adjustment", systemImage: "arrow.left.arrow.right") }
                Button { showCategories = true } label: { Label("Scoop categories", systemImage: "tag") }
            }
            Section("Security") {
                Toggle("Require Face ID, Touch ID, or passcode", isOn: Binding(
                    get: { appLock.isEnabled },
                    set: { enabled in
                        if enabled {
                            Task {
                                if !(await appLock.enable()), appLock.errorMessage != nil { showLockError = true }
                            }
                        } else {
                            appLock.disable()
                        }
                    }
                ))
                Text("Uses Face ID or Touch ID when available, with your device passcode as fallback. Authentication stays on this device.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Your data") {
                Button { do { exportURL = try ledger.exportURL() } catch { exportError = true } } label: { Label("Export ledger backup", systemImage: "square.and.arrow.up") }
                Text("Your financial data stays on this device. Export creates a JSON backup you can save or share.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Privacy") {
                NavigationLink { PrivacyPolicyView() } label: { Label("Privacy policy", systemImage: "hand.raised.fill") }
                Label("No bank connections", systemImage: "building.columns")
                Label("No third party financial services", systemImage: "lock.shield")
            }
            Section("Delete data") {
                Button("Delete all local data", systemImage: "trash", role: .destructive) { confirmDeleteAll = true }
                Text("This permanently removes the ledger and returns the app to first-run setup. Export a backup first if you want to keep a copy.").font(.caption).foregroundStyle(.secondary)
            }
        }.navigationTitle("Settings")
            .sheet(isPresented: $showCategories) { CategoryManagerView() }
            .sheet(isPresented: $showBalanceAdjustment) { TransactionFormView(kind: .balanceAdjustment) }
            .sheet(item: Binding(get: { exportURL.map(ExportFile.init) }, set: { exportURL = $0?.url })) { file in ShareLink(item: file.url) { Label("Share backup", systemImage: "square.and.arrow.up") }.presentationDetents([.medium]) }
            .alert("Couldn’t export backup", isPresented: $exportError) { Button("OK", role: .cancel) {} } message: { Text("Please try again.") }
            .alert("App lock unavailable", isPresented: $showLockError) { Button("OK", role: .cancel) {} } message: { Text(appLock.errorMessage ?? "Authentication could not be completed.") }
            .confirmationDialog("Delete all local data?", isPresented: $confirmDeleteAll, titleVisibility: .visible) {
                Button("Delete all data", role: .destructive) { ledger.resetAllData() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This cannot be undone. Export your ledger first if you want to keep a backup.") }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        List {
            Section("Data stored on your device") {
                Text("Scoops Cash Flow stores the opening balance, income, scoops (expenses), categories, and pay period history in the app’s local data directory. The app has no bank connection, account sign-in, advertising, analytics, or financial data service.")
            }
            Section("Data sharing and backups") {
                Text("The app does not send your ledger to the developer or a third-party server. iOS device backups may include this app’s local data according to your device backup settings. If you choose Export ledger backup, iOS opens the system sharing interface so you can save or share a JSON copy. The destination you choose may store or transmit that copy under its own privacy practices.")
            }
            Section("Retention and deletion") {
                Text("Your ledger remains in the app until you delete it. Use Settings → Delete all local data to erase the ledger from this app, or delete the app from your device. Exported copies are managed separately by the location where you saved or shared them.")
            }
            Section("Security") {
                Text("The ledger file uses iOS Complete Data Protection. iOS stores it encrypted and makes it inaccessible to the app while the device is locked. An exported backup is outside the app’s protection, so choose a destination you trust.")
                Text("Optional app lock uses Apple’s device authentication. Scoops Cash Flow does not receive or store Face ID or Touch ID data.")
            }
            Section("Contact") {
                Link("jamesmcconnellemail@gmail.com", destination: URL(string: "mailto:jamesmcconnellemail@gmail.com")!)
                Text("A public support and privacy-policy website URL will be added before App Store submission.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Privacy policy")
    }
}

private struct ExportFile: Identifiable { let url: URL; var id: String { url.absoluteString }; init(_ url: URL) { self.url = url } }

struct CurrencyView: View {
    @EnvironmentObject private var ledger: LedgerStore
    private let currencies = ["USD", "CAD", "GBP", "EUR", "AUD", "NZD", "CHF"]
    var body: some View {
        List(currencies, id: \.self) { code in
            Button {
                ledger.saveSetup(openingCents: ledger.data.openingBalanceCents, currency: code)
            } label: {
                HStack {
                    Text(Locale.current.localizedString(forCurrencyCode: code) ?? code)
                    Spacer()
                    Text(code).foregroundStyle(.secondary)
                    if ledger.data.currencyCode == code { Image(systemName: "checkmark").foregroundStyle(.tint) }
                }
            }
            .foregroundStyle(.primary)
        }
        .navigationTitle("Currency")
    }
}

struct EmptyState: View {
    let icon: String; let title: String; let message: String
    var body: some View { VStack(spacing: 8) { Image(systemName: icon).font(.system(size: 28)).foregroundStyle(Color(hex: 0x14203D)); Text(title).font(.headline); Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center) }.frame(maxWidth: .infinity).padding(28).background(.background, in: RoundedRectangle(cornerRadius: 18)) }
}
