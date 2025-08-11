//
//  SimpleGoogleButton.swift
//  SplitBudget
//
//  Created by Aurélien on 10/08/2025.
//

import SwiftUI

struct SimpleGoogleButton: View {
    let action: () -> Void
    let isLoading: Bool
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Logo Google simple et efficace
                GoogleSimpleLogo()
                
                Text("Continuer avec Google")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .disabled(isLoading)
    }
}

struct GoogleSimpleLogo: View {
    var body: some View {
        ZStack {
            // Cercle de base
            Circle()
                .fill(Color.white)
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            // Lettre G avec les couleurs Google
            Text("G")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.26, green: 0.52, blue: 0.96), // Google Blue
                            Color(red: 0.22, green: 0.69, blue: 0.29), // Google Green
                            Color(red: 1.0, green: 0.76, blue: 0.03),  // Google Yellow
                            Color(red: 0.92, green: 0.26, blue: 0.21)  // Google Red
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Version simple qui fonctionne toujours")
            .font(.headline)
        
        SimpleGoogleButton(action: {}, isLoading: false)
        
        GoogleSimpleLogo()
            .scaleEffect(2.0)
    }
    .padding()
}
