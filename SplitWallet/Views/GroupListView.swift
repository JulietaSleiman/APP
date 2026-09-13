import SwiftUI

public struct GroupListView: View {
    @State private var viewModel: GroupListViewModel
    @State private var showingCreateGroup = false

    public let currentUser: User

    public init(currentUser: User, viewModel: GroupListViewModel? = nil) {
        self.currentUser = currentUser
        _viewModel = State(initialValue: viewModel ?? GroupListViewModel(currentUserId: currentUser.id))
    }

    public var body: some View {
        NavigationStack {
            List {
                // Section 1: Resumen General Consolidado (Cross-Group)
                Section {
                    crossGroupSummaryCard
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                // Section 2: Lista de Grupos
                Section("Tus Grupos") {
                    if viewModel.groups.isEmpty {
                        ContentUnavailableView(
                            "No tenés grupos activos",
                            systemImage: "person.3.fill",
                            description: Text("Creá un grupo con tu pareja, amigos o roommates para empezar a compartir gastos.")
                        )
                        .padding(.vertical, 24)
                    } else {
                        ForEach(viewModel.groups) { group in
                            NavigationLink {
                                GroupDetailView(
                                    viewModel: GroupDetailViewModel(
                                        group: group,
                                        currentUserId: viewModel.currentUserId
                                    )
                                )
                            } label: {
                                GroupRowView(
                                    group: group,
                                    netBalance: viewModel.netBalance(for: group)
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("SplitWallet")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateGroup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView(
                    viewModel: CreateGroupViewModel(currentUser: currentUser),
                    onGroupCreated: { newGroup in
                        viewModel.addGroupLocally(newGroup)
                    }
                )
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }

    // MARK: - Resumen Cross-Grupo Superior

    private var crossGroupSummaryCard: some View {
        let summaries = viewModel.computeCrossGroupSummaries()

        return VStack(alignment: .leading, spacing: 14) {
            Text("Balance Consolidado")
                .font(.headline)
                .foregroundColor(.secondary)

            if summaries.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.secondary)
                    Text("Estás completamente al día en todos tus grupos.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            } else {
                ForEach(Array(summaries.values), id: \.currency) { summary in
                    HStack(spacing: 16) {
                        // Te deben
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Te deben")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text("\(summary.currency.symbol)\(summary.totalOwedToUser.formatted())")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }

                        Divider()
                            .frame(height: 28)

                        // Debés
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Debés")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text("\(summary.currency.symbol)\(summary.totalUserOwes.formatted())")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                        }

                        Spacer()

                        // Neto consolidado de la divisa
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Neto")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            let net = summary.net
                            Text("\(summary.currency.symbol)\(abs(net).formatted())")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(net > 0 ? .green : (net < 0 ? .red : .secondary))
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

public struct GroupRowView: View {
    public let group: Group
    public let netBalance: Decimal

    public var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.2.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.body)
                    .fontWeight(.semibold)

                Text("\(group.members.count) miembros")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if netBalance > 0 {
                    Text("+\(group.defaultCurrency.symbol)\(netBalance.formatted())")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("te deben")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else if netBalance < 0 {
                    Text("-\(group.defaultCurrency.symbol)\(abs(netBalance).formatted())")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("debés")
                        .font(.caption2)
                        .foregroundColor(.red)
                } else {
                    Text("Al día")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
