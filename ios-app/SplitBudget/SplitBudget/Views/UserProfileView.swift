//
//  UserProfileView.swift
//  SplitBudget
//
//  Created by Aurélien on 11/08/2025.
//

import SwiftUI
import SwiftData

struct UserProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditSheet = false
    @State private var userService: UserService?
    @State private var syncStatus: SyncStatus = .synced
    
    enum SyncStatus {
        case syncing
        case synced
        case needsSync
        case error
        
        var color: Color {
            switch self {
            case .syncing: return .blue
            case .synced: return .green
            case .needsSync: return .orange
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .syncing: return "arrow.clockwise"
            case .synced: return "checkmark.circle"
            case .needsSync: return "exclamationmark.circle"
            case .error: return "xmark.circle"
            }
        }
        
        var text: String {
            switch self {
            case .syncing: return "Synchronisation..."
            case .synced: return "Synchronisé"
            case .needsSync: return "En attente de sync"
            case .error: return "Erreur de sync"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let user = authManager.currentUserModel {
                        // Photo de profil
                        ProfileImageView(user: user)
                            .padding(.top, 20)
                        
                        // Informations utilisateur avec statut sync
                        VStack(spacing: 15) {
                            Text(user.fullName)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Membre depuis le \(user.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Statut de synchronisation
                            HStack(spacing: 8) {
                                Image(systemName: syncStatus.icon)
                                    .foregroundColor(syncStatus.color)
                                    .rotationEffect(.degrees(syncStatus == .syncing ? 360 : 0))
                                    .animation(syncStatus == .syncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: syncStatus)
                                
                                Text(syncStatus.text)
                                    .font(.caption)
                                    .foregroundColor(syncStatus.color)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(syncStatus.color.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.bottom, 20)
                        
                        // Boutons d'action
                        VStack(spacing: 15) {
                            Button("Modifier le profil") {
                                showingEditSheet = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .fontWeight(.semibold)
                            
                            Button("Forcer la synchronisation") {
                                forceSyncUser()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(syncStatus == .syncing ? Color.gray : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .fontWeight(.semibold)
                            .disabled(syncStatus == .syncing)
                            
                            Button("Se déconnecter") {
                                try? authManager.signOut()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 20)
                        
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "person.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("Aucun profil utilisateur")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            Text("Reconnectez-vous pour voir votre profil")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Mon Profil")
            .onAppear {
                setupUserService()
                updateSyncStatus()
            }
            .sheet(isPresented: $showingEditSheet) {
                if let user = authManager.currentUserModel,
                   let userService = userService {
                    EditProfileView(user: user, userService: userService)
                        .onDisappear {
                            updateSyncStatus()
                        }
                }
            }
        }
    }
    
    private func setupUserService() {
        guard userService == nil else { return }
        userService = UserService(modelContext: modelContext)
    }
    
    private func updateSyncStatus() {
        guard let user = authManager.currentUserModel else {
            syncStatus = .error
            return
        }
        
        if user.needsSync {
            syncStatus = .needsSync
        } else {
            syncStatus = .synced
        }
    }
    
    private func forceSyncUser() {
        guard let user = authManager.currentUserModel,
              let userService = userService,
              let firebaseSync = userService.firebaseSyncService else { return }
        
        syncStatus = .syncing
        
        Task {
            do {
                try await firebaseSync.syncUserToFirebase(user)
                await MainActor.run {
                    syncStatus = .synced
                }
            } catch {
                await MainActor.run {
                    syncStatus = .error
                }
                print("❌ Erreur lors de la synchronisation forcée: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Profile Image View
struct ProfileImageView: View {
    let user: UserModel
    
    var body: some View {
        Group {
            if let imageData = user.profileImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let imageURL = user.profileImageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProfilePlaceholderView(initials: user.initials)
                }
            } else {
                ProfilePlaceholderView(initials: user.initials)
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 2)
        )
    }
}

struct ProfilePlaceholderView: View {
    let initials: String
    
    var body: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .overlay(
                Text(initials)
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            )
    }
}

#Preview {
    UserProfileView()
        .environmentObject({
            let authManager = AuthManager()
            return authManager
        }())
        .modelContainer(for: [UserModel.self], inMemory: true)
}
