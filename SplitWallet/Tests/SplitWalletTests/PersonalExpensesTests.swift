import XCTest
@testable import SplitWallet

final class PersonalExpensesTests: XCTestCase {
    var viewModel: PersonalExpensesViewModel!
    let userId = "usr_tester"

    override func setUp() {
        super.setUp()
        viewModel = PersonalExpensesViewModel(userId: userId)
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Test 1: Total spent in selected month ignores other months

    func testTotalSpentInMonth_CalculatesCorrectSum() {
        let calendar = Calendar.current
        let now = Date()
        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else {
            XCTFail("Error generando fecha")
            return
        }

        let exp1 = PersonalExpense(
            userId: userId,
            description: "Supermercado",
            amount: Decimal(150),
            category: .food,
            date: now
        )

        let exp2 = PersonalExpense(
            userId: userId,
            description: "Nafta",
            amount: Decimal(200),
            category: .transport,
            date: now
        )

        let expOld = PersonalExpense(
            userId: userId,
            description: "Gasto del mes pasado",
            amount: Decimal(500),
            category: .shopping,
            date: lastMonth
        )

        viewModel.expenses = [exp1, exp2, expOld]
        viewModel.selectedMonth = now

        XCTAssertEqual(viewModel.totalSpentInSelectedMonth, Decimal(350), "Debe sumar solo los gastos del mes seleccionado")
    }

    // MARK: - Test 2: Category breakdown aggregation and sorting

    func testCategoryBreakdown_AggregatesAndSortsProperly() {
        let now = Date()

        let exp1 = PersonalExpense(
            userId: userId,
            description: "Almuerzo",
            amount: Decimal(100),
            category: .food,
            date: now
        )

        let exp2 = PersonalExpense(
            userId: userId,
            description: "Cena",
            amount: Decimal(150),
            category: .food,
            date: now
        )

        let exp3 = PersonalExpense(
            userId: userId,
            description: "Uber",
            amount: Decimal(80),
            category: .transport,
            date: now
        )

        viewModel.expenses = [exp1, exp2, exp3]
        viewModel.selectedMonth = now

        let breakdown = viewModel.categoryBreakdown
        XCTAssertEqual(breakdown.count, 2)

        // Comida debe estar primero por ser el mayor gasto total ($250 vs $80)
        XCTAssertEqual(breakdown[0].category, .food)
        XCTAssertEqual(breakdown[0].totalAmount, Decimal(250))
        XCTAssertEqual(breakdown[0].count, 2)

        XCTAssertEqual(breakdown[1].category, .transport)
        XCTAssertEqual(breakdown[1].totalAmount, Decimal(80))
        XCTAssertEqual(breakdown[1].count, 1)
    }

    // MARK: - Test 3: Month navigation

    func testMonthNavigation_ShiftsMonthsAccurately() {
        let initial = viewModel.selectedMonth
        viewModel.nextMonth()
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.month, from: viewModel.selectedMonth), (calendar.component(.month, from: initial) % 12) + 1)

        viewModel.previousMonth()
        XCTAssertEqual(calendar.component(.month, from: viewModel.selectedMonth), calendar.component(.month, from: initial))
    }
}
