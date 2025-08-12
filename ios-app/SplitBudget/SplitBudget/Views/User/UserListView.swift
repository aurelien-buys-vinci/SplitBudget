//
//  UserListView.swift
//  SplitBudget
//
//  Created by Aurélien on 11/08/2025.
//

import SwiftUI
import SwiftData

struct UserListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\UserModel.lastName), SortDescriptor(\UserModel.firstName)]) private var users: [UserModel]
    @State private var searchText = ""
    @State private var userService: UserService?
    
    var filteredUsers: [UserModel] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { user in
                user.firstName.localizedCaseInsensitiveContains(searchText) ||
                user.lastName.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredUsers) { user in
                    UserRowView(user: user)
                }
            }
            .searchable(text: $searchText, prompt: "Rechercher un utilisateur...")
            .navigationTitle("Utilisateurs")
            .onAppear {
                setupUserService()
            }
        }
    }
    
    private func setupUserService() {
        if userService == nil {
            userService = UserService(modelContext: modelContext)
        }
    }
}

struct UserRowView: View {
    let user: UserModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Photo de profil
            Group {
                if let imageData = user.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if let imageURL = user.profileImageURL {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .overlay(
                                Text(user.initials)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            )
                    }
                } else {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            Text(user.initials)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        )
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // Informations utilisateur
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Membre depuis \(user.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserModel.self, configurations: config)
    let context = ModelContext(container)
    
    // Ajouter des exemples d'utilisateurs
    let user1 = UserModel(
        id: "1",
        firstName: "Jean",
        lastName: "Dupont",
        email: "jean.dupont@example.com"
    )
    
    let user2 = UserModel(
        id: "2",
        firstName: "Marie",
        lastName: "Martin",
        email: "marie.martin@example.com"
    )
    
    context.insert(user1)
    context.insert(user2)
    
    return UserListView()
        .modelContainer(container)
}
