import Foundation
import Observation

public struct CategoryExpenseTotal: Identifiable, Sendable {
    public var id: String { category.rawValue }
    public let category: PersonalExpenseCategory
    public let totalAmount: Decimal
    public let count: Int
}

@Observable
public final class PersonalExpensesViewModel {
    public var expenses: [PersonalExpense] = []
    public var selectedMonth: Date = Date()
    public var selectedCategoryFilter: PersonalExpenseCategory? = nil
    public var searchText: String = ""

    public let userId: String
    private let localStorage: LocalStorageRepository?

    public init(userId: String, localStorage: LocalStorageRepository? = nil) {
        self.userId = userId
        self.localStorage = localStorage
    }

    public func loadExpenses() {
        if let local = localStorage {
            self.expenses = local.fetchPersonalExpenses(userId: userId)
        }
    }

    // MARK: - Filtros

    public var filteredExpenses: [PersonalExpense] {
        let calendar = Calendar.current
        return expenses.filter { exp in
            let inSelectedMonth = calendar.isDate(exp.date, equalTo: selectedMonth, toGranularity: .month)
            let matchesCategory = selectedCategoryFilter == nil || exp.category == selectedCategoryFilter
            let matchesSearch = searchText.isEmpty || exp.description.localizedCaseInsensitiveContains(searchText)
            return inSelectedMonth && matchesCategory && matchesSearch
        }
    }

    // MARK: - Métricas y Totales

    public var totalSpentInSelectedMonth: Decimal {
        let calendar = Calendar.current
        return expenses
            .filter { calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    public var categoryBreakdown: [CategoryExpenseTotal] {
        let calendar = Calendar.current
        let monthExpenses = expenses.filter { calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }

        var map: [PersonalExpenseCategory: (amount: Decimal, count: Int)] = [:]
        for exp in monthExpenses {
            var curr = map[exp.category, default: (amount: .zero, count: 0)]
            curr.amount += exp.amount
            curr.count += 1
            map[exp.category] = curr
        }

        return map.map { cat, val in
            CategoryExpenseTotal(category: cat, totalAmount: val.amount, count: val.count)
        }.sorted { $0.totalAmount > $1.totalAmount }
    }

    // MARK: - Acciones

    public func addExpenseLocally(_ expense: PersonalExpense) {
        expenses.insert(expense, at: 0)
        localStorage?.savePersonalExpense(expense)
    }

    public func deleteExpenseLocally(id: String) {
        expenses.removeAll(where: { $0.id == id })
        localStorage?.deletePersonalExpense(id: id)
    }

    public func previousMonth() {
        if let prev = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = prev
        }
    }

    public func nextMonth() {
        if let next = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = next
        }
    }
}
