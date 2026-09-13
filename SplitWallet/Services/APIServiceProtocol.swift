import Foundation

public protocol APIServiceProtocol: Sendable {
    func getGroups() async throws -> [Group]
    func getGroupDetails(id: String) async throws -> Group
    func createGroup(name: String, currency: Currency, memberIds: [String]) async throws -> Group

    func getExpenses(groupId: String) async throws -> [Expense]
    func createExpense(_ expense: Expense) async throws -> Expense
    func updateExpense(_ expense: Expense) async throws -> Expense
    func deleteExpense(id: String, groupId: String) async throws

    func getSettlements(groupId: String) async throws -> [Settlement]
    func recordSettlement(_ settlement: Settlement) async throws -> Settlement

    func getBalances(groupId: String) async throws -> [Currency: GroupCurrencyBalance]
}

public enum NetworkError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(statusCode: Int, message: String?)
    case decodingError(Error)
    case offline

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida."
        case .unauthorized: return "Sesión expirada o no autorizada."
        case .serverError(let code, let msg): return "Error del servidor (\(code)): \(msg ?? "Sin detalle")."
        case .decodingError(let err): return "Error decodificando respuesta: \(err.localizedDescription)."
        case .offline: return "Sin conexión a internet."
        }
    }
}
