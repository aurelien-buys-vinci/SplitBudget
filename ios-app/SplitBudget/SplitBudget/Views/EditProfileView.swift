//
//  EditProfileView.swift
//  SplitBudget
//
//  Created by Aurélien on 11/08/2025.
//

import SwiftUI
import PhotosUI
import SwiftData

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let user: UserModel
    let userService: UserService
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false
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
        
        var text: String {
            switch self {
            case .syncing: return "Synchronisation..."
            case .synced: return "Synchronisé"
            case .needsSync: return "En attente de sync"
            case .error: return "Erreur de sync"
            }
        }
    }
    
    init(user: UserModel, userService: UserService) {
        self.user = user
        self.userService = userService
        self._firstName = State(initialValue: user.firstName)
        self._lastName = State(initialValue: user.lastName)
        
        // Charger l'image existante si disponible
        if let imageData = user.profileImageData {
            self._profileImage = State(initialValue: UIImage(data: imageData))
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo de profil avec option de modification
                    VStack(spacing: 15) {
                        Group {
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else if let imageURL = user.profileImageURL, !imageURL.isEmpty {
                                AsyncImage(url: URL(string: imageURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 40))
                                        )
                                }
                            } else {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .overlay(
                                        Text(user.initials)
                                            .font(.title)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                    )
                            }
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray4), lineWidth: 2)
                        )
                        
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Changer la photo", systemImage: "camera.fill")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(20)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Formulaire de modification
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Prénom")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Entrez votre prénom", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.givenName)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nom de famille")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Entrez votre nom", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.familyName)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(user.email)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    Text("Non modifiable")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.trailing, 8)
                                    , alignment: .trailing
                                )
                        }
                        
                        // Section synchronisation
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Synchronisation")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                Image(systemName: syncStatus == .syncing ? "arrow.clockwise" : 
                                      syncStatus == .synced ? "checkmark.circle.fill" :
                                      syncStatus == .needsSync ? "exclamationmark.triangle.fill" : "xmark.circle.fill")
                                    .foregroundColor(syncStatus.color)
                                    .rotationEffect(.degrees(syncStatus == .syncing ? 360 : 0))
                                    .animation(syncStatus == .syncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: syncStatus)
                                
                                Text(syncStatus.text)
                                    .font(.caption)
                                    .foregroundColor(syncStatus.color)
                                
                                Spacer()
                                
                                if syncStatus != .syncing {
                                    Button("Synchroniser") {
                                        forceSyncProfile()
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(syncStatus.color.opacity(0.1))
                            .cornerRadius(8)
                            
                            if let lastSynced = user.lastSyncedAt {
                                Text("Dernière synchronisation: \(lastSynced, style: .relative)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 30)
                    
                    // Boutons d'action
                    VStack(spacing: 15) {
                        Button(action: saveProfile) {
                            if isSaving {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Enregistrement...")
                                }
                            } else {
                                Text("Enregistrer les modifications")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isSaving ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .fontWeight(.semibold)
                        .disabled(isSaving)
                        
                        Button("Annuler") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Modifier le profil")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                updateSyncStatus()
            }
            .onChange(of: selectedPhoto) { _, newPhoto in
                loadSelectedPhoto()
            }
            .alert("Information", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("succès") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func updateSyncStatus() {
        if user.needsSync {
            syncStatus = .needsSync
        } else {
            syncStatus = .synced
        }
    }
    
    private func loadSelectedPhoto() {
        guard let selectedPhoto = selectedPhoto else { return }
        
        Task {
            do {
                if let data = try await selectedPhoto.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        self.profileImage = image
                    }
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Impossible de charger l'image sélectionnée"
                    showingAlert = true
                }
            }
        }
    }
    
    private func saveProfile() {
        isSaving = true
        
        Task {
            do {
                // Mettre à jour les informations de base
                user.firstName = firstName.trimmingCharacters(in: .whitespaces)
                user.lastName = lastName.trimmingCharacters(in: .whitespaces)
                
                // Mettre à jour l'image si elle a changé
                if let profileImage = profileImage {
                    let imageData = profileImage.jpegData(compressionQuality: 0.7)
                    user.updateProfileImage(data: imageData)
                }
                
                try userService.updateUser(user)
                
                await MainActor.run {
                    isSaving = false
                    alertMessage = "Profil mis à jour avec succès!"
                    showingAlert = true
                    updateSyncStatus()
                }
                
            } catch {
                await MainActor.run {
                    isSaving = false
                    alertMessage = "Erreur lors de la sauvegarde: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func forceSyncProfile() {
        guard let firebaseSync = userService.firebaseSyncService else { return }
        
        syncStatus = .syncing
        
        Task {
            do {
                try await firebaseSync.syncUserToFirebase(user)
                
                await MainActor.run {
                    syncStatus = .synced
                    alertMessage = "Synchronisation réussie"
                    showingAlert = true
                }
                
            } catch {
                await MainActor.run {
                    syncStatus = .error
                    alertMessage = "Erreur de synchronisation: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    let userModel = UserModel(
        id: "123",
        firstName: "Jean",
        lastName: "Dupont",
        email: "jean.dupont@example.com"
    )
    
    // Configuration pour un ModelContainer en mémoire
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserModel.self, configurations: config)
    let context = ModelContext(container)
    
    return EditProfileView(
        user: userModel,
        userService: UserService(modelContext: context)
    )
}
