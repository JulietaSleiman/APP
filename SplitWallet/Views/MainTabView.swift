import SwiftUI

public struct MainTabView: View {
    public let currentUser: User
    @State private var selectedTab: Int = 0

    public init(currentUser: User) {
        self.currentUser = currentUser
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            GroupListView(currentUser: currentUser)
                .tabItem {
                    Label("Grupos", systemImage: "person.2.fill")
                }
                .tag(0)

            PersonalExpensesView(viewModel: PersonalExpensesViewModel(userId: currentUser.id))
                .tabItem {
                    Label("Mis Gastos", systemImage: "chart.pie.fill")
                }
                .tag(1)
        }
    }
}
