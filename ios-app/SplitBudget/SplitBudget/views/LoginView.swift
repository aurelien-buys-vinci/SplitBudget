//
//  LoginView.swift
//  SplitBudget
//
//  Created by Aurélien on 10/08/2025.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @StateObject private var authManager = AuthManager()
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showingForgotPassword = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo ou titre de l'application
                VStack(spacing: 10) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("SplitBudget")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Gérez vos dépenses partagées")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // Formulaire de connexion
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    
                    SecureField("Mot de passe", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Boutons d'action
                VStack(spacing: 10) {
                    Button(action: handleAuthAction) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSignUp ? "S'inscrire" : "Se connecter")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    
                    Button(action: { isSignUp.toggle() }) {
                        Text(isSignUp ? "Déjà un compte ? Se connecter" : "Pas de compte ? S'inscrire")
                            .foregroundColor(.blue)
                    }
                    
                    if !isSignUp {
                        Button(action: { showingForgotPassword = true }) {
                            Text("Mot de passe oublié ?")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Divider avec "OU"
                HStack {
                    VStack { Divider() }
                    Text("OU")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                    VStack { Divider() }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                // Boutons de connexion sociale
                VStack(spacing: 12) {
                    // Bouton Google - Version simple et fiable
                    SimpleGoogleButton(action: signInWithGoogle, isLoading: isLoading)
                    
                    // Note informative
                    Text("💡 Connexion rapide et sécurisée avec Google")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .alert("Erreur", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView(authManager: authManager)
        }
    }
    
    private func handleAuthAction() {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    try await authManager.signUp(email: email, password: password)
                } else {
                    try await authManager.signIn(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    alertMessage = getErrorMessage(from: error)
                    showingAlert = true
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func signInWithGoogle() {
        isLoading = true
        
        Task {
            do {
                try await authManager.signInWithGoogle()
            } catch {
                await MainActor.run {
                    alertMessage = "Erreur lors de la connexion Google: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func getErrorMessage(from error: Error) -> String {
        if let authError = error as NSError? {
            switch authError.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                return "Cette adresse email est déjà utilisée."
            case AuthErrorCode.invalidEmail.rawValue:
                return "Adresse email invalide."
            case AuthErrorCode.weakPassword.rawValue:
                return "Le mot de passe doit contenir au moins 6 caractères."
            case AuthErrorCode.userNotFound.rawValue:
                return "Aucun compte trouvé avec cette adresse email."
            case AuthErrorCode.wrongPassword.rawValue:
                return "Mot de passe incorrect."
            default:
                return "Une erreur s'est produite: \(error.localizedDescription)"
            }
        }
        return error.localizedDescription
    }
}

struct ForgotPasswordView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Réinitialiser le mot de passe")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Entrez votre adresse email pour recevoir un lien de réinitialisation")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                
                Button(action: resetPassword) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Envoyer")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(email.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(email.isEmpty || isLoading)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Annuler") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert("Information", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("envoyé") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                try await authManager.resetPassword(email: email)
                await MainActor.run {
                    alertMessage = "Un email de réinitialisation a été envoyé à \(email)"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Erreur: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    LoginView()
}
