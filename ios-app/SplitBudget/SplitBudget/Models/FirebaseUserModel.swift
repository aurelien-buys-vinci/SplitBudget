//
//  FirebaseUserModel.swift
//  SplitBudget
//
//  Created by Aurélien on 11/08/2025.
//

import Foundation
import FirebaseFirestore

// Modèle pour la synchronisation avec Firebase Firestore
struct FirebaseUserModel: Codable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String
    var profileImageURL: String?
    var createdAt: Timestamp
    var updatedAt: Timestamp
    
    // Initializer depuis UserModel
    init(from userModel: UserModel) {
        self.id = userModel.id
        self.firstName = userModel.firstName
        self.lastName = userModel.lastName
        self.email = userModel.email
        self.profileImageURL = userModel.profileImageURL
        self.createdAt = Timestamp(date: userModel.createdAt)
        self.updatedAt = Timestamp(date: userModel.updatedAt)
    }
    
    // Initializer depuis Firestore
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let id = data["id"] as? String,
              let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let email = data["email"] as? String,
              let createdAt = data["createdAt"] as? Timestamp,
              let updatedAt = data["updatedAt"] as? Timestamp else {
            return nil
        }
        
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.profileImageURL = data["profileImageURL"] as? String
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Convertir en dictionnaire pour Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
        
        if let profileImageURL = profileImageURL {
            dict["profileImageURL"] = profileImageURL
        }
        
        return dict
    }
    
    // Mettre à jour un UserModel local avec les données Firebase
    func updateUserModel(_ userModel: UserModel) {
        userModel.firstName = firstName
        userModel.lastName = lastName
        userModel.email = email
        userModel.profileImageURL = profileImageURL
        userModel.createdAt = createdAt.dateValue()
        userModel.updatedAt = updatedAt.dateValue()
        userModel.markAsSynced()
    }
    
    // Vérifier si les données sont plus récentes
    func isNewerThan(_ userModel: UserModel) -> Bool {
        return updatedAt.dateValue() > userModel.updatedAt
    }
}
