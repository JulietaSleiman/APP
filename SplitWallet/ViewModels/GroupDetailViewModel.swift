import Foundation
import Observation

@Observable
public final class GroupDetailViewModel {
    public enum ViewState: Equatable {
        case idle
        case loading
        case error(String)
    }

    public var group: Group
    public var currentUserId: String
    public var expenses: [Expense] = []
    public var settlements: [Settlement] = []
    public var auditLogs: [ExpenseAuditLog] = []
    public var balancesByCurrency: [Currency: GroupCurrencyBalance] = [:]
    public var state: ViewState = .idle

    // MARK: - Filtros de Historial
    public var searchText: String = ""
    public var selectedCategoryFilter: ExpenseCategory? = nil
    public var selectedPayerFilterId: String? = nil

    private let balanceCalculator: BalanceCalculator
    private let reportExporter = GroupReportExporter()
    private let apiService: APIServiceProtocol?

    public init(
        group: Group,
        currentUserId: String,
        balanceCalculator: BalanceCalculator = BalanceCalculator(),
        apiService: APIServiceProtocol? = nil
    ) {
        self.group = group
        self.currentUserId = currentUserId
        self.balanceCalculator = balanceCalculator
        self.apiService = apiService
    }

    // MARK: - Filtered Expenses

    public var filteredExpenses: [Expense] {
        expenses.filter { expense in
            let matchesSearch = searchText.isEmpty || expense.description.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategoryFilter == nil || expense.category == selectedCategoryFilter
            let matchesPayer = selectedPayerFilterId == nil || expense.paidById == selectedPayerFilterId
            return matchesSearch && matchesCategory && matchesPayer
        }
    }

    // MARK: - Balance Calculation

    public func recalculateBalances() {
        do {
            self.balancesByCurrency = try balanceCalculator.calculateBalances(
                members: group.members,
                expenses: expenses,
                settlements: settlements
            )
        } catch {
            self.state = .error("Error al calcular balances: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Getters

    public func userNetBalance(for currency: Currency) -> Decimal {
        guard let groupBalance = balancesByCurrency[currency] else { return .zero }
        return groupBalance.netBalances.first(where: { $0.userId == currentUserId })?.netAmount ?? .zero
    }

    public func simplifiedDebts(for currency: Currency) -> [SimplifiedDebt] {
        balancesByCurrency[currency]?.simplifiedDebts ?? []
    }

    public func auditLogs(for expenseId: String) -> [ExpenseAuditLog] {
        auditLogs.filter { $0.expenseId == expenseId }.sorted(by: { $0.timestamp > $1.timestamp })
    }

    // MARK: - Actions

    public func addExpenseLocally(_ expense: Expense) {
        expenses.insert(expense, at: 0)
        let log = ExpenseAuditLog(
            expenseId: expense.id,
            groupId: group.id,
            modifiedByUserId: currentUserId,
            action: .created,
            newAmount: expense.amount,
            newDescription: expense.description
        )
        auditLogs.append(log)
        recalculateBalances()
    }

    public func updateExpenseLocally(_ updated: Expense, modifiedBy: String) {
        guard let index = expenses.firstIndex(where: { $0.id == updated.id }) else { return }
        let old = expenses[index]
        expenses[index] = updated

        let log = ExpenseAuditLog(
            expenseId: updated.id,
            groupId: group.id,
            modifiedByUserId: modifiedBy,
            action: .updated,
            previousAmount: old.amount,
            newAmount: updated.amount,
            previousDescription: old.description,
            newDescription: updated.description
        )
        auditLogs.append(log)
        recalculateBalances()
    }

    public func deleteExpenseLocally(id: String, modifiedBy: String) {
        guard let index = expenses.firstIndex(where: { $0.id == id }) else { return }
        let old = expenses[index]
        expenses.remove(at: index)

        let log = ExpenseAuditLog(
            expenseId: id,
            groupId: group.id,
            modifiedByUserId: modifiedBy,
            action: .deleted,
            previousAmount: old.amount,
            previousDescription: old.description
        )
        auditLogs.append(log)
        recalculateBalances()
    }

    public func addSettlementLocally(_ settlement: Settlement) {
        settlements.insert(settlement, at: 0)
        recalculateBalances()
    }

    // MARK: - Export

    public func generateCSVExport() -> String {
        reportExporter.generateCSVReport(
            group: group,
            expenses: expenses,
            settlements: settlements,
            balances: balancesByCurrency
        )
    }
}
