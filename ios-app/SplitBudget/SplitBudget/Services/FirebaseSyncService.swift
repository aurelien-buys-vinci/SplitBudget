//
//  FirebaseSyncService.swift
//  SplitBudget
//
//  Created by Aurélien on 11/08/2025.
//

import Foundation
import FirebaseFirestore
import SwiftData

@MainActor
class FirebaseSyncService: ObservableObject {
    private let db = Firestore.firestore()
    private let userService: UserService
    private var listeners: [ListenerRegistration] = []
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    init(userService: UserService) {
        self.userService = userService
    }
    
    deinit {
        // Arrêter tous les listeners de manière synchrone
        for listener in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }
    
    // MARK: - Sync Operations
    
    /// Synchroniser un utilisateur vers Firebase
    func syncUserToFirebase(_ user: UserModel) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        let firebaseUser = FirebaseUserModel(from: user)
        let userRef = db.collection("users").document(user.id)
        
        do {
            try await userRef.setData(firebaseUser.toDictionary(), merge: true)
            user.markAsSynced()
            try userService.updateUser(user)
            print("✅ Utilisateur synchronisé vers Firebase: \(user.fullName)")
        } catch {
            print("❌ Erreur sync vers Firebase: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Synchroniser depuis Firebase vers local
    func syncUserFromFirebase(userId: String) async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        let userRef = db.collection("users").document(userId)
        
        do {
            let document = try await userRef.getDocument()
            
            if document.exists,
               let firebaseUser = FirebaseUserModel(document: document) {
                
                // Vérifier si l'utilisateur existe localement
                if let localUser = userService.getUserById(userId) {
                    // Résoudre les conflits (Firebase plus récent ?)
                    if firebaseUser.isNewerThan(localUser) {
                        firebaseUser.updateUserModel(localUser)
                        try userService.updateUser(localUser)
                        print("✅ Utilisateur mis à jour depuis Firebase: \(localUser.fullName)")
                    }
                } else {
                    // Créer un nouvel utilisateur local
                    let newUser = UserModel(
                        id: firebaseUser.id,
                        firstName: firebaseUser.firstName,
                        lastName: firebaseUser.lastName,
                        email: firebaseUser.email,
                        profileImageURL: firebaseUser.profileImageURL
                    )
                    newUser.createdAt = firebaseUser.createdAt.dateValue()
                    newUser.updatedAt = firebaseUser.updatedAt.dateValue()
                    newUser.markAsSynced()
                    
                    try userService.saveUser(newUser)
                    print("✅ Nouvel utilisateur créé depuis Firebase: \(newUser.fullName)")
                }
            }
        } catch {
            print("❌ Erreur sync depuis Firebase: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Synchroniser tous les utilisateurs locaux qui ont besoin de sync
    func syncPendingUsers() async {
        let allUsers = userService.getAllUsers()
        let pendingUsers = allUsers.filter { $0.needsSync }
        
        for user in pendingUsers {
            do {
                try await syncUserToFirebase(user)
            } catch {
                print("❌ Erreur sync utilisateur \(user.fullName): \(error.localizedDescription)")
                syncError = error.localizedDescription
            }
        }
        
        lastSyncDate = Date()
    }
    
    // MARK: - Real-time Listeners
    
    /// Écouter les changements d'un utilisateur en temps réel
    func startListening(for userId: String) {
        let userRef = db.collection("users").document(userId)
        
        let listener = userRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Erreur listener Firebase: \(error.localizedDescription)")
                Task { @MainActor in
                    self.syncError = error.localizedDescription
                }
                return
            }
            
            guard let document = documentSnapshot,
                  document.exists,
                  let firebaseUser = FirebaseUserModel(document: document) else { return }
            
            Task { @MainActor in
                // Mettre à jour l'utilisateur local si les données Firebase sont plus récentes
                if let localUser = self.userService.getUserById(userId),
                   firebaseUser.isNewerThan(localUser) {
                    
                    firebaseUser.updateUserModel(localUser)
                    do {
                        try self.userService.updateUser(localUser)
                        print("🔄 Utilisateur mis à jour en temps réel: \(localUser.fullName)")
                    } catch {
                        print("❌ Erreur mise à jour temps réel: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        listeners.append(listener)
    }
    
    /// Arrêter tous les listeners
    func stopListening() {
        for listener in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }
    
    // MARK: - Utilities
    
    /// Forcer une synchronisation complète
    func forceSyncUser(_ user: UserModel) async throws {
        user.needsSync = true
        try await syncUserToFirebase(user)
    }
    
    /// Vérifier la connectivité et sync si possible
    func syncIfConnected() async {
        // Pour simplifier, on essaie toujours de sync
        // Dans une vraie app, on vérifierait la connectivité réseau
        await syncPendingUsers()
    }
    
    /// Obtenir le statut de sync d'un utilisateur
    func getSyncStatus(for user: UserModel) -> String {
        if user.needsSync {
            return "En attente de synchronisation"
        } else if let lastSync = user.lastSyncedAt {
            return "Synchronisé le \(lastSync.formatted(date: .abbreviated, time: .shortened))"
        } else {
            return "Jamais synchronisé"
        }
    }
}
