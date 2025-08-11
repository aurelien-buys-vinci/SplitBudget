//
//  MainView.swift
//  SplitBudget
//
//  Created by Aurélien on 10/08/2025.
//

import SwiftUI

struct MainView: View {
    @StateObject private var authManager = AuthManager()
    
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
    }
}

#Preview {
    MainView()
}
