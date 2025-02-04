import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userModel: UserModel
    @Environment(\.dismiss) private var dismiss
    @Binding var monthlyIncome: Double
    @Binding var payPeriod: PayPeriod
    @State private var showSalaryInput = false
    @State private var showPasswordChange = false
    @State private var showPhoneChange = false
    @State private var showLogin = false
    @State private var newPhoneNumber = ""
    @State private var verifyPassword = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
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
                                Text(userModel.phoneNumber)
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
                            Text("INCOME")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.tint)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.mutedGreen.opacity(0.2))
                                .cornerRadius(4)
                            
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
                        
                        // Account Section (Only show if authenticated)
                        if userModel.isAuthenticated {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ACCOUNT")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Theme.tint)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.mutedGreen.opacity(0.2))
                                    .cornerRadius(4)
                                
                                VStack(spacing: 1) {
                                    Button(action: { showPhoneChange = true }) {
                                        HStack {
                                            Text("Change Phone Number")
                                                .font(.system(size: 17))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(Theme.secondaryLabel)
                                        }
                                        .padding()
                                        .background(Theme.surfaceBackground)
                                    }
                                    
                                    Button(action: { showPasswordChange = true }) {
                                        HStack {
                                            Text("Change Password")
                                                .font(.system(size: 17))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(Theme.secondaryLabel)
                                        }
                                        .padding()
                                        .background(Theme.surfaceBackground)
                                    }
                                }
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Authentication Section
                        if !userModel.isAuthenticated {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ACCOUNT")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Theme.tint)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.mutedGreen.opacity(0.2))
                                    .cornerRadius(4)
                                
                                VStack(spacing: 12) {
                                    // Create Account Button
                                    NavigationLink {
                                        SignUpView()
                                    } label: {
                                        HStack {
                                            Text("Create Account")
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
                                    
                                    // Login Button
                                    Button(action: { showLogin = true }) {
                                        HStack {
                                            Text("Log In")
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
                            }
                            .padding(.horizontal)
                        } else {
                            // Logout Button for authenticated users
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
                        }
                    }
                }
                
                // Change Phone Number Sheet
                .sheet(isPresented: $showPhoneChange) {
                    NavigationView {
                        VStack(spacing: 24) {
                            TextField("New Phone Number", text: $newPhoneNumber)
                                .keyboardType(.numberPad)
                                .textFieldStyle(Theme.CustomTextFieldStyle())
                            SecureField("Verify Password", text: $verifyPassword)
                                .textFieldStyle(Theme.CustomTextFieldStyle())
                            
                            Button(action: changePhoneNumber) {
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
                        .navigationTitle("Change Phone")
                        .navigationBarTitleDisplayMode(.inline)
                        .background(Theme.background)
                    }
                }
                
                // Change Password Sheet
                .sheet(isPresented: $showPasswordChange) {
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
                
                                        // Income Update Sheet
                .sheet(isPresented: $showSalaryInput) {
                    SalaryInputSheet(monthlyIncome: $monthlyIncome, payPeriod: $payPeriod)
                        .onDisappear {
                            if userModel.isAuthenticated {
                                userModel.updateUserIncome(monthlyIncome: monthlyIncome, payPeriod: payPeriod)
                            }
                        }
                        .interactiveDismissDisabled()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") {
                                    showSalaryInput = false
                                }
                            }
                        }
                }
                
                // Logout Confirmation Dialog
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
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLogin) {
                LoginView()
                    .environmentObject(userModel)
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func changePhoneNumber() {
        do {
            try userModel.updatePhoneNumber(newPhoneNumber: newPhoneNumber, password: verifyPassword)
            showPhoneChange = false
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func changePassword() {
        guard !currentPassword.isEmpty,
              !newPassword.isEmpty,
              !confirmPassword.isEmpty else {
            alertMessage = "All fields are required"
            showAlert = true
            return
        }
        
        guard newPassword == confirmPassword else {
            alertMessage = "New passwords do not match"
            showAlert = true
            return
        }
        
        do {
            try userModel.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
            showPasswordChange = false
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
