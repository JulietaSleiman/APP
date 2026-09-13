import SwiftUI

public struct GroupDetailView: View {
    @State private var viewModel: GroupDetailViewModel
    @State private var showingAddExpense = false
    @State private var showingSettleSheet = false
    @State private var showingInviteSheet = false
    @State private var selectedExpenseForDetail: Expense? = nil

    public init(viewModel: GroupDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            List {
                // Section 1: Resumen de Balance Personal
                Section {
                    balanceSummaryCard
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                // Section 2: Deudas Simplificadas ("Quién le debe a quién")
                let debts = viewModel.simplifiedDebts(for: viewModel.group.defaultCurrency)
                if !debts.isEmpty {
                    Section("Saldos Simplificados") {
                        ForEach(debts) { debt in
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundColor(.accentColor)
                                
                                Text(userName(for: debt.fromUserId))
                                    .fontWeight(.medium)
                                Text("le debe a")
                                    .foregroundColor(.secondary)
                                Text(userName(for: debt.toUserId))
                                    .fontWeight(.medium)

                                Spacer()

                                Text("\(debt.currency.symbol)\(debt.amount.formatted())")
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                    }
                }

                // Section 3: Filtros de Categoría
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            categoryChip(title: "Todas", category: nil)
                            ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                                categoryChip(title: cat.displayName, category: cat)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color.clear)

                // Section 4: Historial de Gastos Filtrado
                Section("Actividad y Gastos (\(viewModel.filteredExpenses.count))") {
                    if viewModel.filteredExpenses.isEmpty {
                        ContentUnavailableView(
                            "Sin gastos que coincidan",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text("Probá cambiando los filtros o la búsqueda.")
                        )
                        .padding(.vertical, 20)
                    } else {
                        ForEach(viewModel.filteredExpenses) { expense in
                            Button {
                                selectedExpenseForDetail = expense
                            } label: {
                                ExpenseRowView(expense: expense, group: viewModel.group)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.group.name)
            .searchable(text: $viewModel.searchText, prompt: "Buscar en gastos")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettleSheet = true
                    } label: {
                        Text("Saldar")
                            .fontWeight(.medium)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingInviteSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }

                ToolbarItem(placement: .secondaryAction) {
                    ShareLink(
                        item: viewModel.generateCSVExport(),
                        subject: Text("Reporte de Gastos - \(viewModel.group.name)"),
                        message: Text("Adjunto el reporte de gastos y balances de \(viewModel.group.name) en formato CSV.")
                    ) {
                        Label("Exportar CSV", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(
                    viewModel: AddExpenseViewModel(
                        group: viewModel.group,
                        currentUserId: viewModel.currentUserId
                    ),
                    onExpenseAdded: { newExpense in
                        viewModel.addExpenseLocally(newExpense)
                    }
                )
            }
            .sheet(isPresented: $showingSettleSheet) {
                RecordSettlementView(
                    viewModel: RecordSettlementViewModel(
                        group: viewModel.group,
                        defaultFrom: viewModel.currentUserId
                    ),
                    onSettlementRecorded: { newSettlement in
                        viewModel.addSettlementLocally(newSettlement)
                    }
                )
            }
            .sheet(isPresented: $showingInviteSheet) {
                InviteMembersView(group: viewModel.group)
            }
            .sheet(item: $selectedExpenseForDetail) { expense in
                ExpenseDetailSheet(
                    expense: expense,
                    group: viewModel.group,
                    auditLogs: viewModel.auditLogs(for: expense.id),
                    currentUserId: viewModel.currentUserId,
                    onEdit: { updated in
                        viewModel.updateExpenseLocally(updated, modifiedBy: viewModel.currentUserId)
                    },
                    onDelete: { id in
                        viewModel.deleteExpenseLocally(id: id, modifiedBy: viewModel.currentUserId)
                    }
                )
            }
            .onAppear {
                viewModel.recalculateBalances()
            }
        }
    }

    private var balanceSummaryCard: some View {
        let net = viewModel.userNetBalance(for: viewModel.group.defaultCurrency)
        let statusColor: Color = net > 0 ? .green : (net < 0 ? .red : .secondary)

        return VStack(spacing: 8) {
            Text("Tu Balance en el Grupo")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("\(viewModel.group.defaultCurrency.symbol)\(abs(net).formatted())")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(statusColor)

            Text(net > 0 ? "Te deben en total" : (net < 0 ? "Debés en total" : "Estás al día"))
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func categoryChip(title: String, category: ExpenseCategory?) -> some View {
        let isSelected = viewModel.selectedCategoryFilter == category
        return Button {
            viewModel.selectedCategoryFilter = category
        } label: {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(uiColor: .secondarySystemFill))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func userName(for userId: String) -> String {
        viewModel.group.members.first(where: { $0.id == userId })?.name ?? "Usuario"
    }
}

public struct ExpenseRowView: View {
    public let expense: Expense
    public let group: Group

    public var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: expense.category.systemIcon)
                    .foregroundColor(.accentColor)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description)
                    .font(.body)
                    .fontWeight(.medium)

                Text("Pagó \(payerName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(expense.currency.symbol)\(expense.amount.formatted())")
                    .font(.body)
                    .fontWeight(.semibold)

                Text(expense.splitType.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var payerName: String {
        group.members.first(where: { $0.id == expense.paidById })?.name ?? "Alguien"
    }
}
