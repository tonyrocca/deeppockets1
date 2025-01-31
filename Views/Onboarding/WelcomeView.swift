import SwiftUI
import LocalAuthentication

struct WelcomeView: View {
    @StateObject private var userModel = UserModel()
    @State private var showSalaryInput = false
    @State private var showSignUp = false
    
    // Login states
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var rememberMe = false
    @AppStorage("useBiometrics") private var useBiometrics = false
    
    // Animation states
    @State private var animateBackground = false
    @State private var showContent = false
    @State private var showForm = false
    @State private var showButtons = false
    
    private var canShowBiometrics: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background
                Theme.background
                    .ignoresSafeArea()
                    .overlay(
                        ZStack {
                            // Moving gradient circles
                            ForEach(0..<3) { i in
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Theme.tint.opacity(0.2), Color.blue.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 300 - CGFloat(i * 50))
                                    .blur(radius: 30)
                                    .offset(
                                        x: animateBackground ? 50 + CGFloat(i * 20) : -50,
                                        y: animateBackground ? -100 + CGFloat(i * 10) : 100
                                    )
                                    .animation(
                                        Animation.easeInOut(duration: 8)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.5),
                                        value: animateBackground
                                    )
                            }
                        }
                    )
                
                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Logo and Title
                        VStack(spacing: 16) {
                            ZStack {
                                // Animated rings
                                ForEach(0..<3) { i in
                                    Circle()
                                        .stroke(Theme.tint.opacity(0.2), lineWidth: 2)
                                        .frame(width: 100 + CGFloat(i * 20))
                                        .scaleEffect(animateBackground ? 1.1 : 1)
                                        .opacity(animateBackground ? 0 : 1)
                                        .animation(
                                            Animation.easeOut(duration: 2)
                                                .repeatForever(autoreverses: false)
                                                .delay(Double(i) * 0.5),
                                            value: animateBackground
                                        )
                                }
                                
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(Theme.tint)
                                    .scaleEffect(showContent ? 1 : 0.5)
                                    .opacity(showContent ? 1 : 0)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Deep Pockets")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Take control of your finances")
                                    .font(.system(size: 17))
                                    .foregroundColor(Theme.secondaryLabel)
                            }
                            .offset(y: showContent ? 0 : 20)
                            .opacity(showContent ? 1 : 0)
                        }
                        .padding(.top, 60)
                        
                        // Login Form
                        VStack(spacing: 20) {
                            // Phone Input
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(Theme.secondaryLabel)
                                    .frame(width: 24)
                                
                                TextField("", text: Binding(
                                    get: { PhoneNumberFormatter.format(phoneNumber) },
                                    set: { newValue in
                                        let filtered = newValue.filter { $0.isNumber }
                                        if filtered.count <= 10 {
                                            phoneNumber = PhoneNumberFormatter.unformat(newValue)
                                        }
                                    }
                                ))
                                .keyboardType(.numberPad)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .placeholder(when: phoneNumber.isEmpty) {
                                    Text("Phone number")
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.surfaceBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            
                            // Password Input
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(Theme.secondaryLabel)
                                    .frame(width: 24)
                                
                                Group {
                                    if showPassword {
                                        TextField("Password", text: $password)
                                    } else {
                                        SecureField("Password", text: $password)
                                    }
                                }
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.surfaceBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            
                            // Remember Me & Face ID
                            HStack(spacing: 20) {
                                Toggle(isOn: $rememberMe) {
                                    Text("Remember Me")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                }
                                .tint(Theme.tint)
                                
                                if canShowBiometrics {
                                    Toggle(isOn: $useBiometrics) {
                                        Text("Use Face ID")
                                            .font(.system(size: 15))
                                            .foregroundColor(.white)
                                    }
                                    .tint(Theme.tint)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 48)
                        .offset(y: showForm ? 0 : 30)
                        .opacity(showForm ? 1 : 0)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: login) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Log In")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.tint)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .disabled(isLoading)
                            
                            NavigationLink {
                                SignUpView()
                                    .environmentObject(userModel)
                            } label: {
                                Text("Create Account")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        Theme.surfaceBackground
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    )
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
                        .padding(.top, 32)
                        .padding(.bottom, 34)
                        .offset(y: showButtons ? 0 : 50)
                        .opacity(showButtons ? 1 : 0)
                    }
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
            startAnimations()
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
        if let savedPhone = UserDefaults.standard.string(forKey: "savedPhone") {
            phoneNumber = savedPhone
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
                            self.phoneNumber = credentials.phoneNumber
                            self.password = credentials.password
                            login()
                        }
                    }
                }
            }
        }
    }
    
    private func login() {
        guard PhoneNumberFormatter.isValid(phoneNumber) else {
            alertMessage = "Please enter a valid phone number"
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
                try userModel.signIn(phoneNumber: phoneNumber, password: password)
                
                // Save credentials if remember me is enabled
                if rememberMe {
                    UserDefaults.standard.set(phoneNumber, forKey: "savedPhone")
                } else {
                    UserDefaults.standard.removeObject(forKey: "savedPhone")
                }
                
                // Save biometric preference
                if useBiometrics {
                    try userModel.saveBiometricCredentials(phoneNumber: phoneNumber, password: password)
                }
                
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
            isLoading = false
        }
    }
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.6)) {
            showContent = true
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            showForm = true
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
            showButtons = true
        }
        
        animateBackground = true
    }
}
