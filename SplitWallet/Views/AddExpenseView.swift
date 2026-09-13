import SwiftUI
import PhotosUI

public struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddExpenseViewModel
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var receiptPreviewImage: UIImage? = nil
    public var onExpenseAdded: (Expense) -> Void

    public init(viewModel: AddExpenseViewModel, onExpenseAdded: @escaping (Expense) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onExpenseAdded = onExpenseAdded
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: Monto y Descripción
                Section {
                    HStack {
                        Text(viewModel.currency.symbol)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $viewModel.amountString)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                    }

                    TextField("¿En qué se gastó? (ej. Supermercado)", text: $viewModel.description)
                }

                // Section 2: Categoría
                Section("Categoría") {
                    Picker("Categoría", selection: $viewModel.category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.systemIcon).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Section 3: Pagador
                Section("Pagado por") {
                    Picker("Pagador", selection: $viewModel.paidById) {
                        ForEach(viewModel.group.members) { member in
                            Text(member.name).tag(member.id)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Section 4: Forma de División
                Section("División del Gasto") {
                    Picker("Tipo de división", selection: $viewModel.splitType) {
                        ForEach(SplitType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    ForEach($viewModel.participants) { $participant in
                        HStack {
                            Text(userName(for: participant.userId))
                            Spacer()
                            switch viewModel.splitType {
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

                // Section 5: Adjuntar Ticket / Comprobante
                Section("Comprobante / Ticket (Opcional)") {
                    if let image = receiptPreviewImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 140)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            Button(role: .destructive) {
                                receiptPreviewImage = nil
                                viewModel.receiptImageData = nil
                                selectedPhotoItem = nil
                            } label: {
                                Label("Eliminar comprobante", systemImage: "trash")
                                    .font(.footnote)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Adjuntar foto del ticket", systemImage: "camera.fill")
                                .font(.subheadline)
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    viewModel.receiptImageData = data
                                    receiptPreviewImage = UIImage(data: data)
                                }
                            }
                        }
                    }
                }

                // Section 6: Validación
                if let error = viewModel.validationError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Nuevo Gasto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if let expense = viewModel.validateAndBuildExpense() {
                            onExpenseAdded(expense)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func userName(for userId: String) -> String {
        viewModel.group.members.first(where: { $0.id == userId })?.name ?? "Usuario"
    }
}
