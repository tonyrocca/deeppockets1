import SwiftUI

// MARK: - Phone Number Formatter
struct PhoneNumberFormatter {
    static func format(_ number: String) -> String {
        let cleaned = number.filter { $0.isNumber }.prefix(10)
        var result = ""
        
        for (index, char) in cleaned.enumerated() {
            if index == 0 {
                result.append("(")
            }
            if index == 3 {
                result.append(") ")
            }
            if index == 6 {
                result.append("-")
            }
            result.append(char)
        }
        return result
    }
    
    static func unformat(_ number: String) -> String {
        String(number.filter { $0.isNumber }.prefix(10))
    }
    
    static func isValid(_ number: String) -> Bool {
        let cleaned = number.filter { $0.isNumber }
        return cleaned.count == 10
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
    @State private var phoneNumber = ""
    
    var body: some View {
        NavigationStack {
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
                    // Title and Description
                    Text("Phone Number")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("We'll use this to keep your account secure")
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                    
                    // Country Selector
                    HStack {
                        Text("Country/Region")
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryLabel)
                        Spacer()
                        Text("United States (+1)")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                    .padding()
                    .background(Theme.surfaceBackground)
                    .cornerRadius(12)
                    
                    // Phone Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone number")
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryLabel)
                            
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
                            Text("e.g. (555) 555-5555")
                                .foregroundColor(Theme.secondaryLabel)
                        }
                        .padding()
                        .background(Theme.surfaceBackground)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 24)
                
                Spacer()
                
                // Next Button
                NavigationLink {
                    CreatePasswordView(phoneNumber: phoneNumber)
                } label: {
                    Text("Next")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.tint)
                        .cornerRadius(12)
                }
                .disabled(!PhoneNumberFormatter.isValid(phoneNumber))
                .opacity(PhoneNumberFormatter.isValid(phoneNumber) ? 1 : 0.6)
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .navigationBarHidden(true)
            .background(Theme.background)
        }
    }
}

struct CreatePasswordView: View {
    let phoneNumber: String
    @StateObject private var userModel = UserModel()
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var navigateToSalary = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private var requirements: [PasswordRequirement: Bool] {
        PasswordValidator.validate(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Back Button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Title and Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Create Password")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Choose a strong password for your account")
                    .font(.system(size: 17))
                    .foregroundColor(Theme.secondaryLabel)
            }
            .padding(.horizontal)
            .padding(.top, 24)
            
            // Progress Bar (green)
            Rectangle()
                .fill(Theme.tint)
                .frame(height: 2)
                .padding(.top, 24)
            
            // Password Fields
            VStack(alignment: .leading, spacing: 16) {
                // New Password
                HStack {
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
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
                
                // Confirm Password
                HStack {
                    Group {
                        if showConfirmPassword {
                            TextField("Confirm password", text: $confirmPassword)
                        } else {
                            SecureField("Confirm password", text: $confirmPassword)
                        }
                    }
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    
                    Button(action: { showConfirmPassword.toggle() }) {
                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(Theme.secondaryLabel)
                    }
                }
                .padding()
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
                
                // Requirements
                VStack(alignment: .leading, spacing: 16) {
                    Text("Password requirements:")
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                        .padding(.leading, 4)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(PasswordRequirement.allCases, id: \.self) { requirement in
                            HStack(spacing: 12) {
                                Image(systemName: requirements[requirement] ?? false ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(requirements[requirement] ?? false ? Theme.tint : Theme.secondaryLabel)
                                    .frame(width: 20)
                                Text(requirement.description)
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.leading, 4)
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
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .navigationBarHidden(true)
        .background(Theme.background)
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
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match"
            showAlert = true
            return
        }
        
        let requirements = PasswordValidator.validate(password)
        guard requirements.values.allSatisfy({ $0 }) else {
            alertMessage = "Please ensure your password meets all requirements"
            showAlert = true
            return
        }
        
        do {
            try userModel.signUp(phoneNumber: PhoneNumberFormatter.unformat(phoneNumber), password: password)
            navigateToSalary = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
