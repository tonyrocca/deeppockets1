import SwiftUI

struct WelcomeView: View {
    @State private var showSalaryInput = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Logo/Icon Section
                    VStack(spacing: 16) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Theme.tint)
                            .padding(.bottom, 8)
                        
                        Text("Deep Pockets")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Your personal finance companion")
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                    .padding(.top, 100)
                    
                    Spacer()
                    
                    // Feature Highlights
                    VStack(spacing: 24) {
                        featureRow(icon: "chart.pie.fill",
                                 title: "Smart Budgeting",
                                 description: "Create and manage your budget with ease")
                        
                        featureRow(icon: "dollarsign.square.fill",
                                 title: "Affordability Check",
                                 description: "Know what you can really afford")
                        
                        featureRow(icon: "arrow.up.right.circle.fill",
                                 title: "Financial Goals",
                                 description: "Track and achieve your savings goals")
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            // Login action placeholder
                        }) {
                            Text("Log In")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Theme.surfaceBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        
                        Button(action: {
                            // Sign up action placeholder
                        }) {
                            Text("Sign Up")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Theme.tint)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showSalaryInput = true
                        }) {
                            Text("Skip for now")
                                .font(.system(size: 17))
                                .foregroundColor(Theme.secondaryLabel)
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
                }
            }
            .navigationDestination(isPresented: $showSalaryInput) {
                SalaryInputView()
            }
        }
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(Theme.tint)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.secondaryLabel)
            }
            
            Spacer()
        }
    }
}

#Preview {
    WelcomeView()
        .preferredColorScheme(.dark)
}
