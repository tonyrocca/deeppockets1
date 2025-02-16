import SwiftUI
import LocalAuthentication

struct WelcomeView: View {
    @StateObject private var userModel = UserModel()
    @State private var showSalaryInput = false
    
    // Login states
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var rememberMe = false
    @AppStorage("useBiometrics") private var useBiometrics = false
    
    private var canShowBiometrics: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background with subtle gradient
                Theme.background
                    .ignoresSafeArea()
                    .overlay(
                        LinearGradient(
                            colors: [
                                Theme.tint.opacity(0.1),
                                Theme.background,
                                Theme.background
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // App Name and Tagline
                    VStack(spacing: 16) {
                        Text("Deep Pockets")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Know what you can afford\nwith personalized budget insights")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.secondaryLabel)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        NavigationLink {
                            SignUpView()
                                .environmentObject(userModel)
                        } label: {
                            Text("Get Started")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Theme.tint)
                                .cornerRadius(12)
                        }
                        
                        NavigationLink {
                            LoginView()
                                .environmentObject(userModel)
                        } label: {
                            Text("Log In")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(12)
                        }
                        
                        NavigationLink {
                            SalaryInputView()
                                .environmentObject(userModel)
                        } label: {
                            Text("Skip for now")
                                .font(.system(size: 17))
                                .foregroundColor(Theme.secondaryLabel)
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
                }
                
                // Loading overlay
                if isLoading {
                    Color.black
                        .opacity(0.5)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                        )
                }
            }
        }
        .onAppear {
            loadSavedCredentials()
            if useBiometrics {
                authenticateWithBiometrics()
            }
        }
        .onChange(of: userModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                showSalaryInput = true
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadSavedCredentials() {
        if let savedEmail = UserDefaults.standard.string(forKey: "savedEmail") {
            email = savedEmail
        }
    }
    
    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                 localizedReason: "Sign in to your account") { success, error in
                DispatchQueue.main.async {
                    if success {
                        if let credentials = userModel.getBiometricCredentials() {
                                                    self.email = credentials.email
                                                    self.password = credentials.password
                                                    login()
                                                }
                    }
                }
            }
        }
    }
    
    private func login() {
        guard EmailValidator.isValid(email) else {
            alertMessage = "Please enter a valid email address"
            showAlert = true
            return
        }
        
        guard !password.isEmpty else {
            alertMessage = "Please enter your password"
            showAlert = true
            return
        }
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            do {
                try userModel.signIn(email: email, password: password) // Will need to update UserModel to use email
                
                // Save credentials if remember me is enabled
                if rememberMe {
                    UserDefaults.standard.set(email, forKey: "savedEmail")
                } else {
                    UserDefaults.standard.removeObject(forKey: "savedEmail")
                }
                
                // Save biometric preference
                if useBiometrics {
                    try userModel.saveBiometricCredentials(email: email, password: password) // Will need to update UserModel to use email
                }
                
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
            isLoading = false
        }
    }
}
