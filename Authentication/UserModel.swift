import SwiftUI
import Security
import Foundation
import LocalAuthentication

class UserModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var phoneNumber: String = ""
    @Published var currentUser: User? {
        didSet {
            isAuthenticated = currentUser != nil
            if let user = currentUser {
                saveUserData(user)
            }
        }
    }
    
    private let phoneKey = "user_phone"
    private let passwordKey = "user_password"
    
    init() {
        // Try to load saved user data on init
        if let userData = UserDefaults.standard.data(forKey: "userData"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.phoneNumber = user.phoneNumber
        }
    }
    
    struct User: Codable {
        var phoneNumber: String
        var monthlyIncome: Double?
        var payPeriod: PayPeriod?
    }
    
    func signUp(phoneNumber: String, password: String) throws {
        // Validate phone number format
        guard isValidPhoneNumber(phoneNumber) else {
            throw AuthError.invalidPhoneNumber
        }
        
        // Validate password requirements
        guard isValidPassword(password) else {
            throw AuthError.invalidPassword
        }
        
        // Check if user already exists
        if try getStoredPassword(for: phoneNumber) != nil {
            throw AuthError.userAlreadyExists
        }
        
        // Store credentials
        try storeCredentials(phoneNumber: phoneNumber, password: password)
        
        // Create and set current user
        let user = User(phoneNumber: phoneNumber)
        self.currentUser = user
        self.phoneNumber = phoneNumber
    }
    
    func signIn(phoneNumber: String, password: String) throws {
        guard let storedPassword = try getStoredPassword(for: phoneNumber) else {
            throw AuthError.userNotFound
        }
        
        guard password == storedPassword else {
            throw AuthError.invalidCredentials
        }
        
        let user = User(phoneNumber: phoneNumber)
        self.currentUser = user
        self.phoneNumber = phoneNumber
    }
    
    func updatePassword(currentPassword: String, newPassword: String) throws {
        guard let phoneNumber = currentUser?.phoneNumber else {
            throw AuthError.notAuthenticated
        }
        
        // Verify current password
        guard let storedPassword = try getStoredPassword(for: phoneNumber),
              storedPassword == currentPassword else {
            throw AuthError.invalidCredentials
        }
        
        // Validate new password
        guard isValidPassword(newPassword) else {
            throw AuthError.invalidPassword
        }
        
        // Update password
        try storeCredentials(phoneNumber: phoneNumber, password: newPassword)
    }
    
    func updatePhoneNumber(newPhoneNumber: String, password: String) throws {
        guard let currentPhone = currentUser?.phoneNumber else {
            throw AuthError.notAuthenticated
        }
        
        // Verify password
        guard let storedPassword = try getStoredPassword(for: currentPhone),
              storedPassword == password else {
            throw AuthError.invalidCredentials
        }
        
        // Validate new phone number
        guard isValidPhoneNumber(newPhoneNumber) else {
            throw AuthError.invalidPhoneNumber
        }
        
        // Check if new phone number is already in use
        if try getStoredPassword(for: newPhoneNumber) != nil {
            throw AuthError.userAlreadyExists
        }
        
        // Delete old credentials and store new ones
        try deleteCredentials(for: currentPhone)
        try storeCredentials(phoneNumber: newPhoneNumber, password: password)
        
        // Update current user
        var updatedUser = currentUser
        updatedUser?.phoneNumber = newPhoneNumber
        self.currentUser = updatedUser
        self.phoneNumber = newPhoneNumber
    }
    
    func signOut() {
        self.currentUser = nil
        self.phoneNumber = ""
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
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = #"^\d{10}$"#
        return phone.range(of: phoneRegex, options: .regularExpression) != nil
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
        let passwordRegex = #"^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{8,}$"#
        return password.range(of: passwordRegex, options: .regularExpression) != nil
    }
    
    private func storeCredentials(phoneNumber: String, password: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: phoneNumber,
            kSecValueData as String: password.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess && status != errSecDuplicateItem {
            throw AuthError.storageError
        }
    }
    
    private func getStoredPassword(for phoneNumber: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: phoneNumber,
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
    
    private func deleteCredentials(for phoneNumber: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: phoneNumber
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw AuthError.storageError
        }
    }
}

enum AuthError: LocalizedError {
    case invalidPhoneNumber
    case invalidPassword
    case userAlreadyExists
    case userNotFound
    case invalidCredentials
    case notAuthenticated
    case storageError
    
    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "Please enter a valid 10-digit phone number"
        case .invalidPassword:
            return "Password must be at least 8 characters with 1 uppercase, 1 lowercase, and 1 number"
        case .userAlreadyExists:
            return "An account with this phone number already exists"
        case .userNotFound:
            return "No account found with this phone number"
        case .invalidCredentials:
            return "Invalid phone number or password"
        case .notAuthenticated:
            return "Please sign in to perform this action"
        case .storageError:
            return "An error occurred while saving your information"
        }
    }
}

extension UserModel {
    struct BiometricCredentials {
        let phoneNumber: String
        let password: String
    }
    
    func saveBiometricCredentials(phoneNumber: String, password: String) throws {
        let credentials = BiometricCredentials(phoneNumber: phoneNumber, password: password)
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
        case phoneNumber, password
    }
}
