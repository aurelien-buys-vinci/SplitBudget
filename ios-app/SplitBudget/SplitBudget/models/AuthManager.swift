//
//  AuthManager.swift
//  SplitBudget
//
//  Created by Aurélien on 10/08/2025.
//

import Foundation
import FirebaseAuth
import Combine
import GoogleSignIn
import FirebaseCore
import UIKit

class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    
    init() {
        // Écouter les changements d'état d'authentification
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    // Connexion avec email et mot de passe
    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    // Inscription avec email et mot de passe
    func signUp(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }
    
    // Déconnexion
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    // Réinitialisation du mot de passe
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.missingClientID
        }
        
        guard let presentingViewController = await getRootViewController() else {
            throw AuthError.noViewController
        }
        
        // Configuration Google Sign In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.invalidToken
        }
        
        let accessToken = result.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        try await Auth.auth().signIn(with: credential)
    }
    
    // Helper pour obtenir le root view controller de manière moderne
    @MainActor
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
}

// MARK: - Custom Errors
enum AuthError: LocalizedError {
    case missingClientID
    case noViewController
    case invalidToken
    
    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "ID client Google manquant"
        case .noViewController:
            return "Impossible de trouver le contrôleur de vue"
        case .invalidToken:
            return "Token invalide"
        }
    }
}
