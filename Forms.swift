import SwiftUI

struct SetupView: View {
    @EnvironmentObject private var ledger: LedgerStore
    @Environment(\.dismiss) private var dismiss
    @State private var opening = "0.00"
    @State private var currency = ["USD", "CAD", "GBP", "EUR", "AUD", "NZD", "CHF"].contains(Locale.current.currency?.identifier ?? "USD") ? (Locale.current.currency?.identifier ?? "USD") : "USD"
    @State private var error: String?
    private let currencies = ["USD", "CAD", "GBP", "EUR", "AUD", "NZD", "CHF"]
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Start with the cash you have available today. Paychecks and spending will be tracked separately from this starting amount.").font(.subheadline).foregroundStyle(.secondary)
                    HStack { Text("Opening cash"); Spacer(); TextField("0.00", text: $opening).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    Picker("Currency", selection: $currency) { ForEach(currencies, id: \.self) { Text($0).tag($0) } }
                } header: { Text("Your starting point") }
                if let error { Text(error).foregroundStyle(.red).font(.caption) }
            }
            .navigationTitle("Set up Cash Flow")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Get started") { save() }.fontWeight(.semibold) } }
            .interactiveDismissDisabled()
        }
    }
    private func save() {
        guard let cents = Money.cents(from: opening) else { error = "Enter a valid opening balance."; return }
        ledger.saveSetup(openingCents: cents, currency: currency)
        dismiss()
    }
}

struct TransactionFormView: View {
    @EnvironmentObject private var ledger: LedgerStore
    @Environment(\.dismiss) private var dismiss
    let kind: TransactionKind
    var existing: CashTransaction? = nil
    @State private var amount = ""
    @State private var title = ""
    @State private var source = ""
    @State private var date = Date()
    @State private var categoryID: UUID?
    @State private var error: String?
    private var isExpense: Bool { kind == .expense }
    private var isPaycheck: Bool { kind == .paycheck }
    private var isBalanceAdjustment: Bool { kind == .balanceAdjustment }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack { Text("Amount"); Spacer(); TextField("0.00", text: $amount).keyboardType(.decimalPad).multilineTextAlignment(.trailing).font(.title3.weight(.semibold)) }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                if isExpense {
                    Section("Category") {
                        Picker("Category", selection: $categoryID) {
                            Text("Choose a category").tag(UUID?.none)
                            ForEach(ledger.data.categories) { category in Label(category.name, systemImage: category.icon).tag(Optional(category.id)) }
                        }
                    }
                    Section("Details") { TextField("Description or merchant", text: $title) }
                } else if isBalanceAdjustment {
                    Section("Balance adjustment") {
                        TextField("Reason (optional)", text: $title)
                        Text("Use a positive amount to add cash or a negative amount to subtract it.").font(.caption).foregroundStyle(.secondary)
                    }
                } else {
                    Section(isPaycheck ? "Paycheck" : "Income source") {
                        TextField(isPaycheck ? "Source (for example, Employer)" : "Source (for example, Interest)", text: $source)
                        TextField("Description (optional)", text: $title)
                    }
                }
                if let error { Text(error).foregroundStyle(.red).font(.caption) }
            }
            .navigationTitle(existing == nil ? (isExpense ? "Add expense" : isPaycheck ? "Paycheck" : isBalanceAdjustment ? "Balance adjustment" : "Add income") : "Edit transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.fontWeight(.semibold) }
            }
            .onAppear { loadExisting() }
        }
    }
    private func loadExisting() {
        guard let existing else { return }
        amount = Money.input(existing.amountCents); title = existing.title; source = existing.source; date = existing.date; categoryID = existing.categoryID
    }
    private func save() {
        guard let cents = Money.cents(from: amount) else { error = "Enter a valid amount."; return }
        if isBalanceAdjustment {
            guard cents != 0 else { error = "Enter an amount other than zero."; return }
            if var transaction = existing {
                transaction.amountCents = cents
                transaction.title = title.isEmpty ? "Balance adjustment" : title
                transaction.date = date
                ledger.update(transaction)
            } else {
                ledger.addBalanceAdjustment(amountCents: cents, title: title, date: date)
            }
            dismiss()
            return
        }
        guard cents > 0 else { error = "Enter an amount greater than zero."; return }
        if isExpense && categoryID == nil { error = "Choose a category."; return }
        if isExpense, let categoryID {
            if var transaction = existing { transaction.amountCents = cents; transaction.categoryID = categoryID; transaction.title = title.isEmpty ? ledger.categoryName(categoryID) : title; transaction.date = date; ledger.update(transaction) }
            else { ledger.addExpense(amountCents: cents, categoryID: categoryID, title: title, date: date) }
        } else if isPaycheck {
            if var transaction = existing { transaction.amountCents = cents; transaction.title = title.isEmpty ? (source.isEmpty ? "Paycheck" : source) : title; transaction.source = source; transaction.date = date; ledger.update(transaction) }
            else { ledger.addPeriod(paycheckCents: cents, date: date, source: source.isEmpty ? "Paycheck" : source) }
        } else {
            if var transaction = existing { transaction.amountCents = cents; transaction.title = title.isEmpty ? source : title; transaction.source = source; transaction.date = date; ledger.update(transaction) }
            else { ledger.addIncome(amountCents: cents, source: source.isEmpty ? "Other income" : source, title: title, date: date) }
        }
        dismiss()
    }
}

struct NewPeriodView: View {
    @EnvironmentObject private var ledger: LedgerStore
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var date = Date()
    @State private var source = ""
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section { HStack { Text("Paycheck"); Spacer(); TextField("0.00", text: $amount).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }; TextField("Source (optional)", text: $source); DatePicker("Received on", selection: $date, displayedComponents: .date) }
                Section { Text("Your current period will close and its transactions will stay with it. Your available cash carries forward automatically.").font(.subheadline).foregroundStyle(.secondary) }
                if let error { Text(error).foregroundStyle(.red).font(.caption) }
            }.navigationTitle("New pay period")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Start period") { save() }.fontWeight(.semibold) } }
        }
    }
    private func save() { guard let cents = Money.cents(from: amount), cents > 0 else { error = "Enter a paycheck amount greater than zero."; return }; ledger.addPeriod(paycheckCents: cents, date: date, source: source.isEmpty ? "Paycheck" : source); dismiss() }
}

struct CategoryManagerView: View {
    @EnvironmentObject private var ledger: LedgerStore
    @Environment(\.dismiss) private var dismiss
    @State private var editing: ExpenseCategory?
    @State private var showNew = false
    @State private var categoryToDelete: ExpenseCategory?
    var body: some View {
        NavigationStack {
            List {
                ForEach(ledger.data.categories) { category in
                    Button { editing = category } label: { Label(category.name, systemImage: category.icon).foregroundStyle(.primary) }
                        .swipeActions { Button(role: .destructive) { categoryToDelete = category } label: { Label("Delete", systemImage: "trash") } }
                }
            }.navigationTitle("Categories").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }; ToolbarItem(placement: .topBarTrailing) { Button { showNew = true } label: { Image(systemName: "plus") } } }
                .sheet(isPresented: $showNew) { CategoryEditorView() }
                .sheet(item: $editing) { CategoryEditorView(existing: $0) }
                .confirmationDialog("Delete \(categoryToDelete?.name ?? "category")?", isPresented: Binding(get: { categoryToDelete != nil }, set: { if !$0 { categoryToDelete = nil } }), titleVisibility: .visible) {
                    if let category = categoryToDelete {
                        ForEach(ledger.data.categories.filter { $0.id != category.id }) { target in Button("Move transactions to \(target.name)") { ledger.deleteCategory(category, reassignTo: target.id); categoryToDelete = nil } }
                        Button("Cancel", role: .cancel) { categoryToDelete = nil }
                    }
                } message: { Text("Existing expenses will be assigned to another category.") }
        }
    }
}

struct CategoryEditorView: View {
    @EnvironmentObject private var ledger: LedgerStore
    @Environment(\.dismiss) private var dismiss
    var existing: ExpenseCategory? = nil
    @State private var name = ""
    @State private var icon = "tag.fill"
    @State private var error: String?
    private let icons = ["house.fill", "basket.fill", "fork.knife", "car.fill", "bag.fill", "sparkles.tv.fill", "cross.case.fill", "bolt.fill", "repeat", "person.fill", "pawprint.fill", "book.fill", "gift.fill", "tag.fill", "ellipsis.circle.fill"]
    var body: some View {
        NavigationStack {
            Form {
                Section { TextField("Category name", text: $name) }
                Section("Icon") { LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) { ForEach(icons, id: \.self) { symbol in Button { icon = symbol } label: { Image(systemName: symbol).font(.title3).frame(width: 44, height: 44).foregroundStyle(icon == symbol ? .white : Color(hex: 0x286B58)).background(icon == symbol ? Color(hex: 0x286B58) : Color(hex: 0xE8F2ED), in: RoundedRectangle(cornerRadius: 12)) } } }.padding(.vertical, 8) }
                if let error { Text(error).foregroundStyle(.red).font(.caption) }
            }.navigationTitle(existing == nil ? "New category" : "Edit category").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } } }.onAppear { if let existing { name = existing.name; icon = existing.icon } }
        }
    }
    private func save() { let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines); guard !trimmed.isEmpty else { error = "Enter a category name."; return }; if var existing { existing.name = trimmed; existing.icon = icon; ledger.updateCategory(existing) } else { ledger.addCategory(name: trimmed, icon: icon) }; dismiss() }
}
