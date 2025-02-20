import SwiftUI

// MARK: - Email Validator
struct EmailValidator {
    static func format(_ email: String) -> String {
        return email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    static func isValid(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Password Validator
struct PasswordValidator {
    static func validate(_ password: String) -> [PasswordRequirement: Bool] {
        return [
            .length: password.count >= 8,
            .uppercase: password.contains { $0.isUppercase },
            .lowercase: password.contains { $0.isLowercase },
            .number: password.contains { $0.isNumber }
        ]
    }
}

enum PasswordRequirement: CaseIterable {
    case length
    case uppercase
    case lowercase
    case number
    
    var description: String {
        switch self {
        case .length: return "At least 8 characters"
        case .uppercase: return "One uppercase letter"
        case .lowercase: return "One lowercase letter"
        case .number: return "One number"
        }
    }
}

// MARK: - Sign Up Views
struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userModel: UserModel
    @State private var email = ""
    @State private var isTyping = false
    @FocusState private var isEmailFieldFocused: Bool
    
    private var isValid: Bool {
        EmailValidator.isValid(email)
    }
    
    private var showError: Bool {
        !isValid && isTyping && !email.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                    .onTapGesture {
                        isEmailFieldFocused = false
                    }
                VStack(alignment: .leading, spacing: 0) {
                    // Back Button
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Main Content
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("Email Address")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Description
                            Text("We'll use this to keep your account secure")
                                .font(.system(size: 17))
                                .foregroundColor(Theme.secondaryLabel)
                            
                            // Email Input
                            TextField("", text: $email)
                                .focused($isEmailFieldFocused)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .onChange(of: email) { _ in
                                    if !isTyping { isTyping = true }
                                }
                                .placeholder(when: email.isEmpty) {
                                    Text("Enter email address")
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                                .padding()
                                .background(Theme.surfaceBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(showError ? Color.red : Theme.separator, lineWidth: 1)
                                )
                            
                            if showError {
                                Text("Please enter a valid email address")
                                    .font(.system(size: 13))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    Spacer()
                    
                    // Next Button
                    NavigationLink {
                        CreatePasswordView(email: EmailValidator.format(email))
                    } label: {
                        Text("Next")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.tint)
                            .cornerRadius(12)
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.6)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct CreatePasswordView: View {
    let email: String
    @EnvironmentObject var userModel: UserModel
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var navigateToSalary = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isTyping = false
    @State private var isConfirmTyping = false
    @FocusState private var focusedField: PasswordField?
    
    enum PasswordField {
        case password
        case confirmPassword
    }
    
    private var isPasswordValid: Bool {
        password.count >= 6
    }
    
    private var doPasswordsMatch: Bool {
        password == confirmPassword
    }
    
    private var showPasswordError: Bool {
        !isPasswordValid && isTyping && !password.isEmpty
    }
    
    private var showConfirmError: Bool {
        !doPasswordsMatch && isConfirmTyping && !confirmPassword.isEmpty
    }
    
    var body: some View {
        ZStack {
            // Background layer with tap gesture to dismiss the keyboard
            Theme.background
                .ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }
            
            // Main content layer
            VStack(alignment: .leading, spacing: 0) {
                // Back Button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Main Content
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text("Create Password")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Description
                        Text("Choose a strong password for your account")
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryLabel)
                        
                        // Password Fields
                        VStack(alignment: .leading, spacing: 16) {
                            // New Password
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Group {
                                        if showPassword {
                                            TextField("", text: $password)
                                        } else {
                                            SecureField("", text: $password)
                                        }
                                    }
                                    .focused($focusedField, equals: .password)
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                    .onChange(of: password) { _ in
                                        if !isTyping { isTyping = true }
                                    }
                                    .placeholder(when: password.isEmpty) {
                                        Text("Enter password")
                                            .foregroundColor(Theme.secondaryLabel)
                                    }
                                    
                                    Button(action: { showPassword.toggle() }) {
                                        Text(showPassword ? "Hide" : "Show")
                                            .font(.system(size: 17))
                                            .foregroundColor(Theme.secondaryLabel)
                                    }
                                }
                                .padding()
                                .background(Theme.surfaceBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(showPasswordError ? Color.red : Theme.separator, lineWidth: 1)
                                )
                                
                                if showPasswordError {
                                    Text("Password must be at least 6 characters")
                                        .font(.system(size: 13))
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // Confirm Password
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Group {
                                        if showConfirmPassword {
                                            TextField("", text: $confirmPassword)
                                        } else {
                                            SecureField("", text: $confirmPassword)
                                        }
                                    }
                                    .focused($focusedField, equals: .confirmPassword)
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                    .onChange(of: confirmPassword) { _ in
                                        if !isConfirmTyping { isConfirmTyping = true }
                                    }
                                    .placeholder(when: confirmPassword.isEmpty) {
                                        Text("Confirm password")
                                            .foregroundColor(Theme.secondaryLabel)
                                    }
                                    
                                    Button(action: { showConfirmPassword.toggle() }) {
                                        Text(showConfirmPassword ? "Hide" : "Show")
                                            .font(.system(size: 17))
                                            .foregroundColor(Theme.secondaryLabel)
                                    }
                                }
                                .padding()
                                .background(Theme.surfaceBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(showConfirmError ? Color.red : Theme.separator, lineWidth: 1)
                                )
                                
                                if showConfirmError {
                                    Text("Passwords do not match")
                                        .font(.system(size: 13))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 24)
                
                Spacer()
                
                // Complete Button
                Button(action: validateAndComplete) {
                    Text("Complete")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.tint)
                        .cornerRadius(12)
                }
                .disabled(!isPasswordValid || !doPasswordsMatch)
                .opacity(isPasswordValid && doPasswordsMatch ? 1 : 0.6)
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToSalary) {
            SalaryInputView()
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func validateAndComplete() {
        do {
            try userModel.signUp(email: email, password: password)
            navigateToSalary = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

#Preview {
    CreatePasswordView(email: "test@example.com")
}

#Preview {
    SignUpView()
}
