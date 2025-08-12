//
//  UserService.swift
//  SplitBudget
//
//  Created by Aurélien on 11/08/2025.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class UserService: ObservableObject {
    private var modelContext: ModelContext
    var firebaseSyncService: FirebaseSyncService?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        // Le FirebaseSyncService sera configuré après l'initialisation
    }
    
    // Configurer le service de synchronisation Firebase
    @MainActor
    func configureFirebaseSync() {
        if firebaseSyncService == nil {
            firebaseSyncService = FirebaseSyncService(userService: self)
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Sauvegarder un utilisateur
    func saveUser(_ user: UserModel) throws {
        modelContext.insert(user)
        try modelContext.save()
        
        // Synchroniser avec Firebase si configuré
        if let firebaseSync = firebaseSyncService {
            Task {
                do {
                    try await firebaseSync.syncUserToFirebase(user)
                } catch {
                    print("⚠️ Erreur sync Firebase lors de la sauvegarde: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Récupérer un utilisateur par ID
    func getUserById(_ id: String) -> UserModel? {
        let descriptor = FetchDescriptor<UserModel>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let users = try modelContext.fetch(descriptor)
            return users.first
        } catch {
            print("Erreur lors de la récupération de l'utilisateur: \(error)")
            return nil
        }
    }
    
    /// Récupérer un utilisateur par email
    func getUserByEmail(_ email: String) -> UserModel? {
        let descriptor = FetchDescriptor<UserModel>(
            predicate: #Predicate { $0.email == email }
        )
        
        do {
            let users = try modelContext.fetch(descriptor)
            return users.first
        } catch {
            print("Erreur lors de la récupération de l'utilisateur par email: \(error)")
            return nil
        }
    }
    
    /// Récupérer tous les utilisateurs
    func getAllUsers() -> [UserModel] {
        let descriptor = FetchDescriptor<UserModel>(
            sortBy: [SortDescriptor(\.lastName), SortDescriptor(\.firstName)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des utilisateurs: \(error)")
            return []
        }
    }
    
    /// Mettre à jour un utilisateur
    func updateUser(_ user: UserModel) throws {
        user.updateTimestamp()
        try modelContext.save()
        
        // Synchroniser avec Firebase si configuré
        if let firebaseSync = firebaseSyncService {
            Task {
                do {
                    try await firebaseSync.syncUserToFirebase(user)
                } catch {
                    print("⚠️ Erreur sync Firebase lors de la mise à jour: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Supprimer un utilisateur
    func deleteUser(_ user: UserModel) throws {
        modelContext.delete(user)
        try modelContext.save()
    }
    
    /// Supprimer un utilisateur par ID
    func deleteUser(by id: String) throws {
        guard let user = getUserById(id) else {
            throw UserServiceError.userNotFound
        }
        try deleteUser(user)
    }
    
    // MARK: - Méthodes spécialisées
    
    /// Créer ou mettre à jour un utilisateur depuis Google Sign-In
    func createOrUpdateUserFromGoogleSignIn(
        firebaseUID: String,
        email: String,
        displayName: String?,
        profileImageURL: String?
    ) throws -> UserModel {
        
        // Vérifier si l'utilisateur existe déjà
        if let existingUser = getUserById(firebaseUID) {
            // Mettre à jour les informations si nécessaire
            let nameComponents = (displayName ?? "").components(separatedBy: " ")
            let firstName = nameComponents.first ?? ""
            let lastName = nameComponents.count > 1 ? nameComponents.dropFirst().joined(separator: " ") : ""
            
            if existingUser.firstName != firstName || 
               existingUser.lastName != lastName ||
               existingUser.email != email ||
               existingUser.profileImageURL != profileImageURL {
                
                existingUser.firstName = firstName
                existingUser.lastName = lastName
                existingUser.email = email
                existingUser.profileImageURL = profileImageURL
                
                try updateUser(existingUser)
            }
            
            return existingUser
        } else {
            // Créer un nouvel utilisateur
            let newUser = UserModel.createFromGoogleSignIn(
                firebaseUID: firebaseUID,
                email: email,
                displayName: displayName,
                profileImageURL: profileImageURL
            )
            
            try saveUser(newUser)
            return newUser
        }
    }
    
    /// Créer un utilisateur depuis une inscription par email
    func createUserFromEmailSignUp(
        firebaseUID: String,
        email: String,
        firstName: String? = nil,
        lastName: String? = nil
    ) throws -> UserModel {
        
        // Vérifier si l'utilisateur existe déjà
        if let existingUser = getUserById(firebaseUID) {
            return existingUser
        }
        
        let newUser = UserModel.createFromEmailSignUp(
            firebaseUID: firebaseUID,
            email: email,
            firstName: firstName,
            lastName: lastName
        )
        
        try saveUser(newUser)
        return newUser
    }
    
    /// Mettre à jour la photo de profil d'un utilisateur
    func updateUserProfileImage(
        userId: String,
        imageData: Data? = nil,
        imageURL: String? = nil
    ) throws {
        guard let user = getUserById(userId) else {
            throw UserServiceError.userNotFound
        }
        
        if let data = imageData {
            user.updateProfileImage(data: data)
        } else if let url = imageURL {
            user.updateProfileImageURL(url)
        }
        
        try updateUser(user)
    }
    
    /// Rechercher des utilisateurs par nom
    func searchUsers(by name: String) -> [UserModel] {
        // Si le terme de recherche est vide, retourner tous les utilisateurs
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            return getAllUsers()
        }
        
        // Récupérer tous les utilisateurs et filtrer en mémoire
        // car SwiftData ne supporte pas toutes les fonctions Swift dans les prédicats
        let allUsers = getAllUsers()
        let lowercaseName = name.lowercased()
        
        return allUsers.filter { user in
            user.firstName.lowercased().contains(lowercaseName) ||
            user.lastName.lowercased().contains(lowercaseName) ||
            user.email.lowercased().contains(lowercaseName)
        }
    }
    
    /// Rechercher des utilisateurs par nom avec prédicat SwiftData (recherche exacte)
    func searchUsersWithPredicate(by name: String) -> [UserModel] {
        let descriptor = FetchDescriptor<UserModel>(
            predicate: #Predicate { user in
                user.firstName.contains(name) ||
                user.lastName.contains(name) ||
                user.email.contains(name)
            },
            sortBy: [SortDescriptor(\.lastName), SortDescriptor(\.firstName)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la recherche d'utilisateurs: \(error)")
            return []
        }
    }
}

// MARK: - Erreurs personnalisées
enum UserServiceError: LocalizedError {
    case userNotFound
    case invalidData
    case saveError
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "Utilisateur non trouvé"
        case .invalidData:
            return "Données invalides"
        case .saveError:
            return "Erreur lors de la sauvegarde"
        }
    }
}
