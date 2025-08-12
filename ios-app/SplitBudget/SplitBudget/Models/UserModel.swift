//
//  UserModel.swift
//  SplitBudget
//
//  Created by Aurélien on 11/08/2025.
//

import Foundation
import SwiftData

@Model
final class UserModel {
    @Attribute(.unique) var id: String
    var firstName: String
    var lastName: String
    var email: String
    var profileImageData: Data?
    var profileImageURL: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Champs pour la synchronisation Firebase
    var lastSyncedAt: Date?
    var needsSync: Bool
    var firebaseDocumentId: String?
    
    // Propriétés calculées
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return firstInitial + lastInitial
    }
    
    // Initializer
    init(
        id: String,
        firstName: String,
        lastName: String,
        email: String,
        profileImageData: Data? = nil,
        profileImageURL: String? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.profileImageData = profileImageData
        self.profileImageURL = profileImageURL
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastSyncedAt = nil
        self.needsSync = true
        self.firebaseDocumentId = id // Utiliser l'ID Firebase comme document ID
    }
    
    // Méthode pour mettre à jour le timestamp
    func updateTimestamp() {
        self.updatedAt = Date()
        self.needsSync = true
    }
    
    // Méthode pour marquer comme synchronisé
    func markAsSynced() {
        self.lastSyncedAt = Date()
        self.needsSync = false
    }
    
    // Méthode pour mettre à jour la photo de profil avec des données
    func updateProfileImage(data: Data?) {
        self.profileImageData = data
        self.profileImageURL = nil // On privilégie les données locales
        updateTimestamp()
    }
    
    // Méthode pour mettre à jour la photo de profil avec une URL
    func updateProfileImageURL(_ url: String?) {
        self.profileImageURL = url
        self.profileImageData = nil // On privilégie l'URL si pas de données locales
        updateTimestamp()
    }
}

// MARK: - Extensions pour faciliter l'utilisation

extension UserModel {
    
    // Créer un utilisateur à partir des informations Google Sign-In
    static func createFromGoogleSignIn(
        firebaseUID: String,
        email: String,
        displayName: String?,
        profileImageURL: String?
    ) -> UserModel {
        // Extraire prénom et nom du displayName
        let nameComponents = (displayName ?? "").components(separatedBy: " ")
        let firstName = nameComponents.first ?? ""
        let lastName = nameComponents.count > 1 ? nameComponents.dropFirst().joined(separator: " ") : ""
        
        return UserModel(
            id: firebaseUID,
            firstName: firstName,
            lastName: lastName,
            email: email,
            profileImageURL: profileImageURL
        )
    }
    
    // Créer un utilisateur à partir d'une inscription par email
    static func createFromEmailSignUp(
        firebaseUID: String,
        email: String,
        firstName: String? = nil,
        lastName: String? = nil
    ) -> UserModel {
        let defaultFirstName = firstName ?? email.components(separatedBy: "@").first ?? "Utilisateur"
        let defaultLastName = lastName ?? ""
        
        return UserModel(
            id: firebaseUID,
            firstName: defaultFirstName,
            lastName: defaultLastName,
            email: email
        )
    }
}

// MARK: - Comparable pour le tri
extension UserModel: Comparable {
    static func < (lhs: UserModel, rhs: UserModel) -> Bool {
        if lhs.lastName != rhs.lastName {
            return lhs.lastName < rhs.lastName
        }
        return lhs.firstName < rhs.firstName
    }
}
