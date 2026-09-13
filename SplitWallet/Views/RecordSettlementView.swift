import SwiftUI

public struct RecordSettlementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RecordSettlementViewModel
    public var onSettlementRecorded: (Settlement) -> Void

    public init(viewModel: RecordSettlementViewModel, onSettlementRecorded: @escaping (Settlement) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSettlementRecorded = onSettlementRecorded
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(viewModel.currency.symbol)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $viewModel.amountString)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Detalle del Pago") {
                    Picker("Quién pagó", selection: $viewModel.fromUserId) {
                        ForEach(viewModel.group.members) { member in
                            Text(member.name).tag(member.id)
                        }
                    }

                    Picker("Quién recibió", selection: $viewModel.toUserId) {
                        ForEach(viewModel.group.members) { member in
                            Text(member.name).tag(member.id)
                        }
                    }
                }

                Section("Nota (Opcional)") {
                    TextField("ej. Transferencia Mercado Pago", text: $viewModel.note)
                }

                if let error = viewModel.validationError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Registrar Pago")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmar") {
                        if let settlement = viewModel.buildSettlement() {
                            onSettlementRecorded(settlement)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
