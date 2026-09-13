import SwiftUI
import Charts

public struct PersonalExpensesView: View {
    @State private var viewModel: PersonalExpensesViewModel
    @State private var showingAddExpense = false

    public init(viewModel: PersonalExpensesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            List {
                // Section 1: Selector de Mes y Total
                Section {
                    VStack(spacing: 16) {
                        monthNavigator

                        Divider()

                        VStack(spacing: 4) {
                            Text("Total Gastado en el Mes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("$\(viewModel.totalSpentInSelectedMonth.formatted())")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))

                // Section 2: Gráfico de Gastos por Categoría (Swift Charts)
                if !viewModel.categoryBreakdown.isEmpty {
                    Section("Distribución por Categoría") {
                        VStack(alignment: .leading, spacing: 12) {
                            Chart(viewModel.categoryBreakdown) { item in
                                BarMark(
                                    x: .value("Monto", item.totalAmount),
                                    y: .value("Categoría", item.category.displayName)
                                )
                                .foregroundStyle(by: .value("Categoría", item.category.displayName))
                                .cornerRadius(6)
                            }
                            .chartLegend(.hidden)
                            .frame(height: CGFloat(max(140, viewModel.categoryBreakdown.count * 34)))
                            .padding(.vertical, 6)
                        }
                    }
                }

                // Section 3: Listado de Gastos
                Section("Historial (\(viewModel.filteredExpenses.count))") {
                    if viewModel.filteredExpenses.isEmpty {
                        ContentUnavailableView(
                            "Sin gastos en este período",
                            systemImage: "creditcard",
                            description: Text("Tocá el botón + para registrar tus compras o pagos personales.")
                        )
                        .padding(.vertical, 20)
                    } else {
                        ForEach(viewModel.filteredExpenses) { expense in
                            PersonalExpenseRowView(expense: expense)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let id = viewModel.filteredExpenses[index].id
                                viewModel.deleteExpenseLocally(id: id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Mis Gastos")
            .searchable(text: $viewModel.searchText, prompt: "Buscar en gastos personales")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddPersonalExpenseView(
                    userId: viewModel.userId,
                    onExpenseAdded: { newExp in
                        viewModel.addExpenseLocally(newExp)
                    }
                )
            }
            .onAppear {
                viewModel.loadExpenses()
            }
        }
    }

    private var monthNavigator: some View {
        HStack {
            Button {
                viewModel.previousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(viewModel.selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Button {
                viewModel.nextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
    }
}

public struct PersonalExpenseRowView: View {
    public let expense: PersonalExpense

    public var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: expense.category.systemIcon)
                    .foregroundColor(.accentColor)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description)
                    .font(.body)
                    .fontWeight(.medium)

                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(expense.currency.symbol)\(expense.amount.formatted())")
                    .font(.body)
                    .fontWeight(.semibold)

                Text(expense.category.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
