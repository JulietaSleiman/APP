import SwiftUI

public struct AddPersonalExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    public let userId: String
    public var onExpenseAdded: (PersonalExpense) -> Void

    @State private var amountString = ""
    @State private var description = ""
    @State private var category: PersonalExpenseCategory = .food
    @State private var currency: Currency = .ARS
    @State private var date = Date()
    @State private var note = ""
    @State private var validationError: String?

    public init(userId: String, onExpenseAdded: @escaping (PersonalExpense) -> Void) {
        self.userId = userId
        self.onExpenseAdded = onExpenseAdded
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: Monto
                Section {
                    HStack {
                        Text(currency.symbol)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amountString)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                    }

                    TextField("¿En qué gastaste? (ej. Café con medialunas)", text: $description)
                }

                // Section 2: Categoría
                Section("Categoría") {
                    Picker("Categoría", selection: $category) {
                        ForEach(PersonalExpenseCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.systemIcon).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Moneda", selection: $currency) {
                        ForEach(Currency.allCases, id: \.self) { curr in
                            Text("\(curr.rawValue) (\(curr.symbol))").tag(curr)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Section 3: Fecha y Nota
                Section("Detalles") {
                    DatePicker("Fecha", selection: $date, displayedComponents: .date)
                    TextField("Nota personal (opcional)", text: $note)
                }

                if let error = validationError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Nuevo Gasto Personal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let clean = amountString.replacingOccurrences(of: ",", with: ".")
        guard let amount = Decimal(string: clean), amount > 0 else {
            validationError = "Ingresá un monto válido mayor a 0."
            return
        }

        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationError = "Por favor ingresá una descripción."
            return
        }

        let expense = PersonalExpense(
            userId: userId,
            description: description.trimmingCharacters(in: .whitespaces),
            amount: amount,
            currency: currency,
            category: category,
            date: date,
            note: note.isEmpty ? nil : note
        )

        onExpenseAdded(expense)
        dismiss()
    }
}
