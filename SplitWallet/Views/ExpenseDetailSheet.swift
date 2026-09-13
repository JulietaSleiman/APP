import SwiftUI

public struct ExpenseDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let expense: Expense
    public let group: Group
    public let auditLogs: [ExpenseAuditLog]
    public let currentUserId: String
    public var onEdit: (Expense) -> Void
    public var onDelete: (String) -> Void

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    public init(
        expense: Expense,
        group: Group,
        auditLogs: [ExpenseAuditLog],
        currentUserId: String,
        onEdit: @escaping (Expense) -> Void,
        onDelete: @escaping (String) -> Void
    ) {
        self.expense = expense
        self.group = group
        self.auditLogs = auditLogs
        self.currentUserId = currentUserId
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    public var body: some View {
        NavigationStack {
            List {
                // Cabecera Principal
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label(expense.category.displayName, systemImage: expense.category.systemIcon)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.accentColor)
                            Spacer()
                            Text(expense.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text(expense.description)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("\(expense.currency.symbol)\(expense.amount.formatted())")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("Pagado íntegramente por \(payerName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                // Sección de Comprobante / Ticket
                if let receiptURL = expense.receiptUrl {
                    Section("Comprobante del Gasto") {
                        ReceiptImageView(imageURL: receiptURL)
                    }
                }

                // Desglose de Participantes
                Section("Desglose (\(expense.splitType.displayName))") {
                    ForEach(expense.participants) { part in
                        HStack {
                            Text(userName(for: part.userId))
                            Spacer()
                            if let computed = part.computedAmount {
                                Text("\(expense.currency.symbol)\(computed.formatted())")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }

                // Historial de Auditoría
                if !auditLogs.isEmpty {
                    Section("Historial de Cambios") {
                        ForEach(auditLogs) { log in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(actionText(for: log.action))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(log.action == .deleted ? .red : .accentColor)
                                    Spacer()
                                    Text(log.timestamp.formatted(date: .numeric, time: .shortened))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Text("Por: \(userName(for: log.modifiedByUserId))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if let prev = log.previousAmount, let new = log.newAmount, prev != new {
                                    Text("Monto: \(expense.currency.symbol)\(prev.formatted()) ➔ \(expense.currency.symbol)\(new.formatted())")
                                        .font(.caption2)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                // Acciones
                Section {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Editar Gasto", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Eliminar Gasto", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Detalle del Gasto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditExpenseView(
                    expense: expense,
                    group: group,
                    onSave: { updated in
                        onEdit(updated)
                        dismiss()
                    }
                )
            }
            .alert("¿Eliminar este gasto?", isPresented: $showingDeleteAlert) {
                Button("Eliminar", role: .destructive) {
                    onDelete(expense.id)
                    dismiss()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción recalculará inmediatamente los balances de todos los miembros del grupo.")
            }
        }
    }

    private var payerName: String {
        userName(for: expense.paidById)
    }

    private func userName(for userId: String) -> String {
        group.members.first(where: { $0.id == userId })?.name ?? "Usuario"
    }

    private func actionText(for action: ExpenseAuditAction) -> String {
        switch action {
        case .created: return "Gasto Registrado"
        case .updated: return "Gasto Modificado"
        case .deleted: return "Gasto Eliminado"
        }
    }
}
