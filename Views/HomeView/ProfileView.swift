import SwiftUI
import LocalAuthentication

// MARK: - ValidationError
enum ValidationError: LocalizedError {
    case emptyField(String)
    case passwordMismatch
    
    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "\(field) is required"
        case .passwordMismatch:
            return "New passwords do not match"
        }
    }
}

// MARK: - ProfileView
struct ProfileView: View {
    @EnvironmentObject var userModel: UserModel
    @Environment(\.dismiss) private var dismiss
    @Binding var monthlyIncome: Double
    @Binding var payPeriod: PayPeriod
    
    // Sheet States
    @State private var showSalaryInput = false
    @State private var showPasswordChange = false
    @State private var showEmailChange = false
    @State private var showLogin = false
    
    // Form Fields
    @State private var newEmail = ""
    @State private var verifyPassword = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    // Alert States
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 12) {
                            Circle()
                                .fill(Theme.surfaceBackground)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(Theme.secondaryLabel)
                                )
                            
                            if userModel.isAuthenticated {
                                Text(userModel.email)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("Guest User")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Income Section
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("INCOME")
                            
                            Button(action: { showSalaryInput = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Monthly Income")
                                            .font(.system(size: 17))
                                            .foregroundColor(.white)
                                        Text("\(formatCurrency(monthlyIncome))/month")
                                            .font(.system(size: 15))
                                            .foregroundColor(Theme.secondaryLabel)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                                .padding()
                                .background(Theme.surfaceBackground)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Tutorial Help Section
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("HELP & SUPPORT")
                            
                            Button(action: {
                                // Reset the tutorial flag to show it again
                                UserDefaults.standard.set(false, forKey: "hasSeenAffordabilityTutorial")
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 18))
                                    Text("View App Tutorial")
                                        .font(.system(size: 17))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                                .padding()
                                .background(Theme.surfaceBackground)
                                .cornerRadius(12)
                            }
                            
                            // Optional: Add additional help options here
                            Button(action: {
                                // You could add an action to open a help website or documentation
                            }) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 18))
                                    Text("App Guide")
                                        .font(.system(size: 17))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                                .padding()
                                .background(Theme.surfaceBackground)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Account Section (Only show if authenticated)
                        if userModel.isAuthenticated {
                            VStack(alignment: .leading, spacing: 8) {
                                sectionHeader("ACCOUNT")
                                
                                VStack(spacing: 1) {
                                    accountButton("Change Email") {
                                        showEmailChange = true
                                    }
                                    
                                    accountButton("Change Password") {
                                        showPasswordChange = true
                                    }
                                }
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                            // Logout Button
                            VStack(alignment: .leading, spacing: 8) {
                                Button(action: { showLogoutConfirmation = true }) {
                                    HStack {
                                        Text("Logout")
                                            .font(.system(size: 17))
                                            .foregroundColor(.red)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Theme.surfaceBackground)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            // Authentication Section for guests
                            VStack(alignment: .leading, spacing: 8) {
                                sectionHeader("ACCOUNT")
                                
                                VStack(spacing: 12) {
                                    NavigationLink {
                                        SignUpView()
                                    } label: {
                                        accountButton("Create Account")
                                    }
                                    
                                    Button(action: { showLogin = true }) {
                                        accountButton("Log In")
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // All sheets and dialogs
                .sheet(isPresented: $showEmailChange) {
                    emailChangeSheet
                }
                .sheet(isPresented: $showPasswordChange) {
                    passwordChangeSheet
                }
                .sheet(isPresented: $showSalaryInput) {
                    SalaryInputSheet(monthlyIncome: $monthlyIncome, payPeriod: $payPeriod)
                        .onDisappear {
                            if userModel.isAuthenticated {
                                userModel.updateUserIncome(monthlyIncome: monthlyIncome, payPeriod: payPeriod)
                            }
                        }
                        .interactiveDismissDisabled()
                }
                .sheet(isPresented: $showLogin) {
                    LoginView()
                        .environmentObject(userModel)
                }
                .confirmationDialog(
                    "Are you sure you want to logout?",
                    isPresented: $showLogoutConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Logout", role: .destructive) {
                        userModel.signOut()
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .alert("Error", isPresented: $showAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(alertMessage)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Sheet Views
    private var emailChangeSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                TextField("New Email Address", text: $newEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(Theme.CustomTextFieldStyle())
                SecureField("Verify Password", text: $verifyPassword)
                    .textFieldStyle(Theme.CustomTextFieldStyle())
                
                Button(action: changeEmail) {
                    Text("Save")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.tint)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Change Email")
            .navigationBarTitleDisplayMode(.inline)
            .background(Theme.background)
        }
    }
    
    private var passwordChangeSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                SecureField("Current Password", text: $currentPassword)
                    .textFieldStyle(Theme.CustomTextFieldStyle())
                SecureField("New Password", text: $newPassword)
                    .textFieldStyle(Theme.CustomTextFieldStyle())
                SecureField("Confirm New Password", text: $confirmPassword)
                    .textFieldStyle(Theme.CustomTextFieldStyle())
                
                Button(action: changePassword) {
                    Text("Save")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.tint)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .background(Theme.background)
        }
    }
    
    // MARK: - Helper Views
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(Theme.tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.mutedGreen.opacity(0.2))
            .cornerRadius(4)
    }
    
    private func accountButton(_ title: String, action: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Theme.secondaryLabel)
        }
        .padding()
        .background(Theme.surfaceBackground)
        .onTapGesture {
            action?()
        }
    }
    
    // MARK: - Actions
    private func changeEmail() {
        do {
            guard !newEmail.isEmpty else {
                throw ValidationError.emptyField("Email")
            }
            guard !verifyPassword.isEmpty else {
                throw ValidationError.emptyField("Password")
            }
            
            try userModel.updateEmail(newEmail: newEmail, password: verifyPassword)
            showEmailChange = false
            
            // Clear form
            newEmail = ""
            verifyPassword = ""
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func changePassword() {
        do {
            guard !currentPassword.isEmpty else {
                throw ValidationError.emptyField("Current password")
            }
            guard !newPassword.isEmpty else {
                throw ValidationError.emptyField("New password")
            }
            guard !confirmPassword.isEmpty else {
                throw ValidationError.emptyField("Confirm password")
            }
            guard newPassword == confirmPassword else {
                throw ValidationError.passwordMismatch
            }
            
            try userModel.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
            showPasswordChange = false
            
            // Clear form
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - SalaryInputSheet
struct SalaryInputSheet: View {
    @Binding var monthlyIncome: Double
    @Binding var payPeriod: PayPeriod
    @Environment(\.dismiss) private var dismiss
    @State private var paycheck: String = ""
    @State private var selectedPayPeriod: PayPeriod?
    @State private var showPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    // Pay Period Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pay Frequency")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showPicker.toggle()
                            }
                        }) {
                            HStack {
                                Text(selectedPayPeriod?.rawValue ?? "Select frequency")
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .rotationEffect(showPicker ? .degrees(180) : .degrees(0))
                            }
                            .padding()
                            .background(Theme.surfaceBackground)
                            .cornerRadius(12)
                        }
                        
                        if showPicker {
                            CustomPickerView(
                                selectedPayPeriod: $selectedPayPeriod,
                                isPresented: $showPicker
                            )
                        }
                    }
                    
                    // Take Home Pay Input
                    if selectedPayPeriod != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Take Home Pay")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("$")
                                    .foregroundColor(.white)
                                TextField("", text: $paycheck)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.white)
                                if let period = selectedPayPeriod {
                                    Text("/\(period.rawValue.lowercased())")
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                            }
                            .padding()
                            .background(Theme.surfaceBackground)
                            .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                    
                    // Save Button
                    if !paycheck.isEmpty && selectedPayPeriod != nil {
                        Button(action: saveIncome) {
                            Text("Save")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Theme.tint)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
                .navigationTitle("Update Income")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            selectedPayPeriod = payPeriod
            paycheck = String(format: "%.0f", monthlyIncome / payPeriod.multiplier)
        }
    }
    
    private func saveIncome() {
        if let amount = Double(paycheck),
           let period = selectedPayPeriod {
            monthlyIncome = amount * period.multiplier
            payPeriod = period
            dismiss()
        }
    }
}
