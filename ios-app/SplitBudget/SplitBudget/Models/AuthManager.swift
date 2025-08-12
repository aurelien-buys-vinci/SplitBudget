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
import SwiftData

class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var currentUserModel: UserModel?
    @Published var isAuthenticated = false
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var userService: UserService?
    
    init() {
        // Écouter les changements d'état d'authentification
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
                
                if let user = user, let userService = self?.userService {
                    self?.loadCurrentUser(firebaseUID: user.uid, userService: userService)
                } else {
                    self?.currentUserModel = nil
                }
            }
        }
    }
    
    // Configurer le service utilisateur (à appeler depuis la vue principale)
    func configureUserService(_ userService: UserService) {
        self.userService = userService
        
        // Configurer Firebase Sync dans le contexte du main actor
        Task { @MainActor in
            userService.configureFirebaseSync()
        }
        
        // Si un utilisateur est déjà connecté, charger ses données et commencer la sync
        if let user = user {
            Task { @MainActor in
                loadCurrentUser(firebaseUID: user.uid, userService: userService)
                
                // Démarrer la synchronisation temps réel
                if let firebaseSync = userService.firebaseSyncService {
                    firebaseSync.startListening(for: user.uid)
                    await firebaseSync.syncIfConnected()
                }
            }
        }
    }
    
    deinit {
        // Supprimer le listener quand l'objet est détruit
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // Connexion avec email et mot de passe
    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    // Inscription avec email et mot de passe
    func signUp(email: String, password: String) async throws {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Créer l'utilisateur dans SwiftData
        if let userService = userService {
            try await createUserInDatabase(
                firebaseUID: authResult.user.uid,
                email: email,
                userService: userService
            )
        }
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
        
        let authResult = try await Auth.auth().signIn(with: credential)
        
        // Créer ou mettre à jour l'utilisateur dans SwiftData
        if let userService = userService {
            try await createOrUpdateUserFromGoogle(
                firebaseUID: authResult.user.uid,
                googleUser: result.user,
                userService: userService
            )
        }
    }
    
    // MARK: - User Management
    
    @MainActor
    private func loadCurrentUser(firebaseUID: String, userService: UserService) {
        currentUserModel = userService.getUserById(firebaseUID)
        
        // Si l'utilisateur n'existe pas localement, essayer de le récupérer depuis Firebase
        if currentUserModel == nil, let firebaseSync = userService.firebaseSyncService {
            Task {
                do {
                    try await firebaseSync.syncUserFromFirebase(userId: firebaseUID)
                    currentUserModel = userService.getUserById(firebaseUID)
                } catch {
                    print("⚠️ Impossible de récupérer l'utilisateur depuis Firebase: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @MainActor
    private func createUserInDatabase(
        firebaseUID: String,
        email: String,
        userService: UserService
    ) async throws {
        let userModel = try userService.createUserFromEmailSignUp(
            firebaseUID: firebaseUID,
            email: email
        )
        currentUserModel = userModel
    }
    
    @MainActor
    private func createOrUpdateUserFromGoogle(
        firebaseUID: String,
        googleUser: GIDGoogleUser,
        userService: UserService
    ) async throws {
        let userModel = try userService.createOrUpdateUserFromGoogleSignIn(
            firebaseUID: firebaseUID,
            email: googleUser.profile?.email ?? "",
            displayName: googleUser.profile?.name,
            profileImageURL: googleUser.profile?.imageURL(withDimension: 320)?.absoluteString
        )
        currentUserModel = userModel
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
