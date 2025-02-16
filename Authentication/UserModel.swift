import SwiftUI
import Security
import Foundation
import LocalAuthentication

class UserModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var email: String = ""
    @Published var currentUser: User? {
        didSet {
            isAuthenticated = currentUser != nil
            if let user = currentUser {
                saveUserData(user)
            }
        }
    }
    
    init() {
        // Try to load saved user data on init
        if let userData = UserDefaults.standard.data(forKey: "userData"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.email = user.email
        }
    }
    
    struct User: Codable {
        var email: String
        var monthlyIncome: Double?
        var payPeriod: PayPeriod?
    }
    
    func signUp(email: String, password: String) throws {
        // Validate email format
        guard EmailValidator.isValid(email) else {
            throw AuthError.invalidEmail
        }
        
        // Validate password requirements
        guard isValidPassword(password) else {
            throw AuthError.invalidPassword
        }
        
        // Check if user already exists
        if try getStoredPassword(for: email) != nil {
            throw AuthError.userAlreadyExists
        }
        
        // Store credentials
        try storeCredentials(email: email, password: password)
        
        // Create and set current user
        let user = User(email: email)
        self.currentUser = user
        self.email = email
    }
    
    func signIn(email: String, password: String) throws {
        guard let storedPassword = try getStoredPassword(for: email) else {
            throw AuthError.userNotFound
        }
        
        guard password == storedPassword else {
            throw AuthError.invalidCredentials
        }
        
        let user = User(email: email)
        self.currentUser = user
        self.email = email
    }
    
    func updatePassword(currentPassword: String, newPassword: String) throws {
        guard let email = currentUser?.email else {
            throw AuthError.notAuthenticated
        }
        
        // Verify current password
        guard let storedPassword = try getStoredPassword(for: email),
              storedPassword == currentPassword else {
            throw AuthError.invalidCredentials
        }
        
        // Validate new password
        guard isValidPassword(newPassword) else {
            throw AuthError.invalidPassword
        }
        
        // Update password
        try storeCredentials(email: email, password: newPassword)
    }
    
    func updateEmail(newEmail: String, password: String) throws {
        guard let currentEmail = currentUser?.email else {
            throw AuthError.notAuthenticated
        }
        
        // Verify password
        guard let storedPassword = try getStoredPassword(for: currentEmail),
              storedPassword == password else {
            throw AuthError.invalidCredentials
        }
        
        // Validate new email
        guard EmailValidator.isValid(newEmail) else {
            throw AuthError.invalidEmail
        }
        
        // Check if new email is already in use
        if try getStoredPassword(for: newEmail) != nil {
            throw AuthError.userAlreadyExists
        }
        
        // Delete old credentials and store new ones
        try deleteCredentials(for: currentEmail)
        try storeCredentials(email: newEmail, password: password)
        
        // Update current user
        var updatedUser = currentUser
        updatedUser?.email = newEmail
        self.currentUser = updatedUser
        self.email = newEmail
    }
    
    func signOut() {
        self.currentUser = nil
        self.email = ""
        UserDefaults.standard.removeObject(forKey: "userData")
    }
    
    func updateUserIncome(monthlyIncome: Double, payPeriod: PayPeriod) {
        var updatedUser = currentUser
        updatedUser?.monthlyIncome = monthlyIncome
        updatedUser?.payPeriod = payPeriod
        self.currentUser = updatedUser
    }
    
    // MARK: - Helper Methods
    
    private func saveUserData(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "userData")
        }
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // Only check for minimum length now
        return password.count >= 6
    }
    
    private func storeCredentials(email: String, password: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecValueData as String: password.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess && status != errSecDuplicateItem {
            throw AuthError.storageError
        }
    }
    
    private func getStoredPassword(for email: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess,
              let passwordData = result as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            throw AuthError.storageError
        }
        
        return password
    }
    
    private func deleteCredentials(for email: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw AuthError.storageError
        }
    }
}

enum AuthError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case userAlreadyExists
    case userNotFound
    case invalidCredentials
    case notAuthenticated
    case storageError
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPassword:
            return "Password must be at least 6 characters"
        case .userAlreadyExists:
            return "An account with this email already exists"
        case .userNotFound:
            return "No account found with this email"
        case .invalidCredentials:
            return "Invalid email or password"
        case .notAuthenticated:
            return "Please sign in to perform this action"
        case .storageError:
            return "An error occurred while saving your information"
        }
    }
}

extension UserModel {
    struct BiometricCredentials {
        let email: String
        let password: String
    }
    
    func saveBiometricCredentials(email: String, password: String) throws {
        let credentials = BiometricCredentials(email: email, password: password)
        let data = try JSONEncoder().encode(credentials)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "biometricLogin",
            kSecValueData as String: data,
            kSecAttrAccessControl as String: SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryAny,
                nil
            )!
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw AuthError.storageError
        }
    }
    
    func getBiometricCredentials() -> BiometricCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "biometricLogin",
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let credentials = try? JSONDecoder().decode(BiometricCredentials.self, from: data)
        else {
            return nil
        }
        
        return credentials
    }
    
    func removeBiometricCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "biometricLogin"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// Make BiometricCredentials Codable
extension UserModel.BiometricCredentials: Codable {
    private enum CodingKeys: String, CodingKey {
        case email, password
    }
}
