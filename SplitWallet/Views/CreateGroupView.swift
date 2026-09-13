import SwiftUI

public struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateGroupViewModel
    public var onGroupCreated: (Group) -> Void

    public init(viewModel: CreateGroupViewModel, onGroupCreated: @escaping (Group) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onGroupCreated = onGroupCreated
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Información del Grupo") {
                    TextField("Nombre del grupo (ej. Depto con Male)", text: $viewModel.name)

                    Picker("Moneda principal", selection: $viewModel.defaultCurrency) {
                        ForEach(Currency.allCases, id: \.self) { curr in
                            Text("\(curr.rawValue) (\(curr.symbol))").tag(curr)
                        }
                    }
                }

                Section("Miembros del Grupo") {
                    ForEach(viewModel.members) { member in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.title3)

                            VStack(alignment: .leading) {
                                Text(member.name)
                                    .fontWeight(.medium)
                                if !member.email.isEmpty {
                                    Text(member.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            if member.id == viewModel.currentUser.id {
                                Text("Tú")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.15))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.removeMember(at: index)
                        }
                    }

                    // Input para agregar nuevo miembro
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Nombre del nuevo miembro", text: $viewModel.newMemberName)
                        TextField("Email (opcional)", text: $viewModel.newMemberEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)

                        Button {
                            viewModel.addMember()
                        } label: {
                            Label("Agregar Miembro", systemImage: "plus.circle.fill")
                                .fontWeight(.medium)
                        }
                        .disabled(viewModel.newMemberName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.vertical, 4)
                }

                if let error = viewModel.validationError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Crear Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if let group = viewModel.buildGroup() {
                            onGroupCreated(group)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
