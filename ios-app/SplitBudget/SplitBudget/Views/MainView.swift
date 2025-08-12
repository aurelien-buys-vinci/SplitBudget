//
//  MainView.swift
//  SplitBudget
//
//  Created by Aurélien on 10/08/2025.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @StateObject private var authManager = AuthManager()
    @Environment(\.modelContext) private var modelContext
    @State private var userService: UserService?
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
        .onAppear {
            setupUserService()
        }
    }
    
    private func setupUserService() {
        if userService == nil {
            userService = UserService(modelContext: modelContext)
            authManager.configureUserService(userService!)
        }
    }
}

#Preview {
    MainView()
}
