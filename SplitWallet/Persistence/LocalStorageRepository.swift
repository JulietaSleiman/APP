import Foundation
import SwiftData

@MainActor
public final class LocalStorageRepository {
    private let modelContainer: ModelContainer
    public var modelContext: ModelContext {
        modelContainer.mainContext
    }

    public init(inMemory: Bool = false) {
        let schema = Schema([
            SDUser.self,
            SDGroup.self,
            SDExpense.self,
            SDSplitParticipant.self,
            SDSettlement.self,
            SDPersonalExpense.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }

    // MARK: - Groups

    public func fetchGroups() -> [Group] {
        let descriptor = FetchDescriptor<SDGroup>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toDomain() }
        } catch {
            print("Error fetching groups from SwiftData: \(error)")
            return []
        }
    }

    public func saveGroup(_ group: Group) {
        let entity = SDGroup(from: group)
        modelContext.insert(entity)
        try? modelContext.save()
    }

    // MARK: - Expenses

    public func saveExpense(_ expense: Expense) {
        let entity = SDExpense(from: expense)
        modelContext.insert(entity)
        try? modelContext.save()
    }

    // MARK: - Settlements

    public func saveSettlement(_ settlement: Settlement) {
        let entity = SDSettlement(from: settlement)
        modelContext.insert(entity)
        try? modelContext.save()
    }

    // MARK: - Personal Expenses

    public func fetchPersonalExpenses(userId: String) -> [PersonalExpense] {
        let predicate = #Predicate<SDPersonalExpense> { $0.userId == userId }
        let descriptor = FetchDescriptor<SDPersonalExpense>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.map { $0.toDomain() }
        } catch {
            print("Error fetching personal expenses: \(error)")
            return []
        }
    }

    public func savePersonalExpense(_ expense: PersonalExpense) {
        let entity = SDPersonalExpense(from: expense)
        modelContext.insert(entity)
        try? modelContext.save()
    }

    public func deletePersonalExpense(id: String) {
        let predicate = #Predicate<SDPersonalExpense> { $0.id == id }
        let descriptor = FetchDescriptor<SDPersonalExpense>(predicate: predicate)
        if let entities = try? modelContext.fetch(descriptor), let entity = entities.first {
            modelContext.delete(entity)
            try? modelContext.save()
        }
    }
}
