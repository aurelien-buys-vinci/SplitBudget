//
//  GoogleSignInButton.swift
//  SplitBudget
//
//  Created by Aurélien on 10/08/2025.
//

import SwiftUI

struct GoogleSignInButton: View {
    let action: () -> Void
    let isLoading: Bool
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Essayons plusieurs options pour le logo Google
                
                // Option 1: Image téléchargée (si elle fonctionne)
                if let _ = UIImage(named: "GoogleLogo") {
                    Image("GoogleLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                } else {
                    // Option 2: Fallback avec SF Symbol coloré
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.red, .yellow, .green, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 20, height: 20)
                        
                        Text("G")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
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

#Preview {
    VStack(spacing: 20) {
        Text("Bouton Google avec logo officiel")
            .font(.headline)
        
        GoogleSignInButton(action: {}, isLoading: false)
        
        GoogleSignInButton(action: {}, isLoading: true)
            .opacity(0.6)
        
        Text("Logo officiel Google utilisé")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}
