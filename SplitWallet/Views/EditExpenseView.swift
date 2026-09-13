import SwiftUI

public struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    public let originalExpense: Expense
    public let group: Group
    public var onSave: (Expense) -> Void

    @State private var description: String
    @State private var amountString: String
    @State private var category: ExpenseCategory
    @State private var paidById: String
    @State private var splitType: SplitType
    @State private var participants: [SplitParticipant]
    @State private var validationError: String?

    private let calculator = BalanceCalculator()

    public init(expense: Expense, group: Group, onSave: @escaping (Expense) -> Void) {
        self.originalExpense = expense
        self.group = group
        self.onSave = onSave

        _description = State(initialValue: expense.description)
        _amountString = State(initialValue: expense.amount.formatted())
        _category = State(initialValue: expense.category)
        _paidById = State(initialValue: expense.paidById)
        _splitType = State(initialValue: expense.splitType)
        _participants = State(initialValue: expense.participants)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Información Básica") {
                    HStack {
                        Text(originalExpense.currency.symbol)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amountString)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                    }

                    TextField("Descripción", text: $description)
                }

                Section("Detalles") {
                    Picker("Categoría", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.systemIcon).tag(cat)
                        }
                    }

                    Picker("Pagado por", selection: $paidById) {
                        ForEach(group.members) { member in
                            Text(member.name).tag(member.id)
                        }
                    }
                }

                Section("División") {
                    Picker("Tipo", selection: $splitType) {
                        ForEach(SplitType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    ForEach($participants) { $participant in
                        HStack {
                            Text(userName(for: participant.userId))
                            Spacer()
                            switch splitType {
                            case .equal:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            case .exact:
                                TextField("Monto", value: $participant.shareValue, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            case .percentage:
                                HStack(spacing: 2) {
                                    TextField("%", value: $participant.shareValue, format: .number)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 60)
                                    Text("%")
                                }
                            case .shares:
                                HStack(spacing: 2) {
                                    TextField("Partes", value: $participant.shareValue, format: .number)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 50)
                                    Text("pts")
                                }
                            }
                        }
                    }
                }

                if let error = validationError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Editar Gasto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar Cambios") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveChanges() {
        let clean = amountString.replacingOccurrences(of: ",", with: ".")
        guard let amount = Decimal(string: clean), amount > 0 else {
            validationError = "Ingresá un monto válido mayor a 0."
            return
        }

        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationError = "La descripción no puede estar vacía."
            return
        }

        do {
            let computed = try calculator.computeParticipantShares(
                totalAmount: amount,
                splitType: splitType,
                participants: participants,
                paidById: paidById
            )

            var updated = originalExpense
            updated.amount = amount
            updated.description = description
            updated.category = category
            updated.paidById = paidById
            updated.splitType = splitType
            updated.participants = computed
            updated.updatedAt = Date()

            onSave(updated)
            dismiss()
        } catch {
            validationError = error.localizedDescription
        }
    }

    private func userName(for userId: String) -> String {
        group.members.first(where: { $0.id == userId })?.name ?? "Usuario"
    }
}
