import SwiftUI
import SwiftData

@main
struct SplitWalletApp: App {
    @State private var authManager = AuthenticationManager(
        currentUser: User(
            id: "usr_me",
            name: "Juan Perez",
            email: "juan@splitwallet.app",
            authMethod: .apple
        )
    )

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SDUser.self,
            SDGroup.self,
            SDExpense.self,
            SDSplitParticipant.self,
            SDSettlement.self,
            SDPersonalExpense.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if let currentUser = authManager.currentUser, authManager.isAuthenticated {
                    MainTabView(currentUser: currentUser)
                } else {
                    AuthView(authManager: authManager)
                }
            }
            .task {
                _ = await NotificationManager.shared.requestAuthorization()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
