import SwiftUI

struct SignUpView: View {
    @StateObject private var userModel = UserModel()
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToSalary = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Navigation Bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Set up your account to save your preferences")
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryLabel)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // Phone Number Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                            
                            TextField("", text: $phoneNumber)
                                .keyboardType(.numberPad)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .placeholder(when: phoneNumber.isEmpty) {
                                    Text("Enter 10-digit phone number")
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                                .padding()
                                .background(Theme.surfaceBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.separator, lineWidth: 1)
                                )
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                            
                            SecureField("", text: $password)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .placeholder(when: password.isEmpty) {
                                    Text("Enter password")
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                                .padding()
                                .background(Theme.surfaceBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.separator, lineWidth: 1)
                                )
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                            
                            SecureField("", text: $confirmPassword)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .placeholder(when: confirmPassword.isEmpty) {
                                    Text("Confirm password")
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                                .padding()
                                .background(Theme.surfaceBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.separator, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Password Requirements
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password must contain:")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            requirementText("At least 8 characters")
                            requirementText("One uppercase letter")
                            requirementText("One lowercase letter")
                            requirementText("One number")
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    // Sign Up Button
                    Button(action: signUp) {
                        Text("Create Account")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.tint)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationDestination(isPresented: $navigateToSalary) {
                SalaryInputView()
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func requirementText(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 4))
            Text(text)
        }
        .foregroundColor(Theme.secondaryLabel)
        .font(.system(size: 15))
    }
    
    private func signUp() {
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match"
            showAlert = true
            return
        }
        
        do {
            try userModel.signUp(phoneNumber: phoneNumber, password: password)
            navigateToSalary = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

#Preview {
    SignUpView()
        .preferredColorScheme(.dark)
}
