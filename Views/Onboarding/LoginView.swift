import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var userModel: UserModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var rememberMe = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToSalary = false
    @AppStorage("useBiometrics") private var useBiometrics = false
    
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Custom Navigation Bar with Back Button
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
                    Text("Welcome Back")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Sign in to access your account")
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                }
                .padding(.top, 20)
                
                // Form Fields
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                        
                        TextField("", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .placeholder(when: email.isEmpty) {
                                Text("Enter email address")
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
                        
                        HStack {
                            if showPassword {
                                TextField("", text: $password)
                                    .font(.system(size: 17))
                            } else {
                                SecureField("", text: $password)
                                    .font(.system(size: 17))
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Text(showPassword ? "Hide" : "Show")
                                    .font(.system(size: 17))
                                    .foregroundColor(Theme.secondaryLabel)
                            }
                        }
                        .foregroundColor(.white)
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
                
                // Remember Me & Face ID Options
                VStack(spacing: 16) {
                    Toggle(isOn: $rememberMe) {
                        Text("Remember Me")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                    .tint(Theme.tint)
                    
                    if LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                        Toggle(isOn: $useBiometrics) {
                            Text("Use Face ID")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                        }
                        .tint(Theme.tint)
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Login Button
                Button(action: login) {
                    Text("Sign In")
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
        .navigationBarBackButtonHidden(true) // Hide the default back button
        .onAppear {
            // Check if we should attempt biometric login
            if useBiometrics {
                authenticateWithBiometrics()
            }
            
            // Load saved credentials if remember me was enabled
            if let savedEmail = UserDefaults.standard.string(forKey: "savedEmail") {
                email = savedEmail
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .navigationDestination(isPresented: $navigateToSalary) {
            SalaryInputView()
        }
    }
    
    private func login() {
        do {
            try userModel.signIn(email: email, password: password)
            
            // Save credentials if remember me is enabled
            if rememberMe {
                UserDefaults.standard.set(email, forKey: "savedEmail")
            } else {
                UserDefaults.standard.removeObject(forKey: "savedEmail")
            }
            
            // Save biometric preference
            if useBiometrics {
                try userModel.saveBiometricCredentials(email: email, password: password)
            }
            
            navigateToSalary = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
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
                        // Try to get stored credentials
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
}

#Preview {
    LoginView()
        .environmentObject(UserModel())
        .preferredColorScheme(.dark)
}
