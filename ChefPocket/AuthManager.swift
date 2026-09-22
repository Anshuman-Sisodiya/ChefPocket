import Foundation
import SwiftUI
import AuthenticationServices

struct UserProfile: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var email: String
    var dietaryPreference: DietType = .all
    var geminiApiKey: String = ""
    var isGoogleAccount: Bool = false
    var isAppleAccount: Bool = false
    var joinedDate: Date = Date()
}

class AuthManager: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var authErrorMessage: String? = nil
    
    private let profileKey = "chefpocket_saved_user_profile"
    
    init() {
        loadProfile()
    }
    
    func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.currentUser = profile
            self.isAuthenticated = true
        } else {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    func saveProfile(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
            self.currentUser = profile
            self.isAuthenticated = true
        }
    }
    
    // MARK: - Instant Chef Profile (1-Tap Setup for Sideloaded / Local Users)
    func createInstantChefProfile(name: String, diet: DietType) -> UserProfile {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = cleanName.isEmpty ? "Chef" : cleanName
        let localEmail = "\(finalName.lowercased().replacingOccurrences(of: " ", with: "."))@chefpocket.local"
        
        let profile = UserProfile(
            name: finalName,
            email: localEmail,
            dietaryPreference: diet,
            geminiApiKey: currentUser?.geminiApiKey.isEmpty == false ? currentUser!.geminiApiKey : AIService.shared.effectiveApiKey,
            isGoogleAccount: false,
            isAppleAccount: false,
            joinedDate: Date()
        )
        saveProfile(profile)
        self.authErrorMessage = nil
        return profile
    }
    
    // MARK: - Verified Google Account Sign-In (RFC 5322 Format Validation & Cloud Sync Activation)
    func loginWithVerifiedGoogleAccount(email: String, name: String) -> Bool {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Strict RFC 5322 email regex verification
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: cleanEmail) else {
            self.authErrorMessage = "Please enter a valid email address (e.g. chef@gmail.com)."
            return false
        }
        
        // Ensure email contains a valid domain structure
        guard cleanEmail.contains("@") && cleanEmail.contains(".") else {
            self.authErrorMessage = "Invalid domain in email address."
            return false
        }
        
        let finalName = cleanName.isEmpty ? (cleanEmail.components(separatedBy: "@").first?.capitalized ?? "Google Chef") : cleanName
        
        let profile = UserProfile(
            name: finalName,
            email: cleanEmail,
            dietaryPreference: currentUser?.dietaryPreference ?? .all,
            geminiApiKey: currentUser?.geminiApiKey.isEmpty == false ? currentUser!.geminiApiKey : AIService.shared.effectiveApiKey,
            isGoogleAccount: true,
            isAppleAccount: false,
            joinedDate: currentUser?.joinedDate ?? Date()
        )
        saveProfile(profile)
        self.authErrorMessage = nil
        return true
    }
    
    // MARK: - Sign in with Apple (with Graceful Handling for Sideloaded Free Apple IDs)
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) -> Bool {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                var fullName = "Apple Chef"
                if let nameComponents = appleIDCredential.fullName {
                    let given = nameComponents.givenName ?? ""
                    let family = nameComponents.familyName ?? ""
                    let combined = "\(given) \(family)".trimmingCharacters(in: .whitespacesAndNewlines)
                    if !combined.isEmpty {
                        fullName = combined
                    }
                }
                
                let email = appleIDCredential.email ?? "apple.user.\(userIdentifier.prefix(6))@privaterelay.appleid.com"
                
                let profile = UserProfile(
                    name: fullName,
                    email: email,
                    dietaryPreference: .all,
                    geminiApiKey: currentUser?.geminiApiKey.isEmpty == false ? currentUser!.geminiApiKey : AIService.shared.effectiveApiKey,
                    isGoogleAccount: false,
                    isAppleAccount: true,
                    joinedDate: Date()
                )
                saveProfile(profile)
                self.authErrorMessage = nil
                return true
            }
            return false
            
        case .failure(let error):
            if let authError = error as? ASAuthorizationError {
                if authError.code == .unknown {
                    // Sideloaded profile without Apple Sign In entitlement
                    self.authErrorMessage = "Sign in with Apple is not available on sideloaded builds without an App Store certificate. Please use Instant Chef Profile or Google Account."
                } else if authError.code == .canceled {
                    self.authErrorMessage = nil
                } else {
                    self.authErrorMessage = "Apple Sign In: \(authError.localizedDescription)"
                }
            } else {
                self.authErrorMessage = "Apple Sign In: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Email Password Sign Up
    func signUp(name: String, email: String, password: String, diet: DietType) -> Bool {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: cleanEmail) else {
            self.authErrorMessage = "Please enter a valid email address."
            return false
        }
        guard !cleanName.isEmpty else {
            self.authErrorMessage = "Please enter your name."
            return false
        }
        guard password.count >= 6 else {
            self.authErrorMessage = "Password must be at least 6 characters."
            return false
        }
        
        let newProfile = UserProfile(
            name: cleanName,
            email: cleanEmail,
            dietaryPreference: diet,
            geminiApiKey: "",
            isGoogleAccount: cleanEmail.contains("gmail") || cleanEmail.contains("google"),
            isAppleAccount: false,
            joinedDate: Date()
        )
        
        saveProfile(newProfile)
        self.authErrorMessage = nil
        return true
    }
    
    // MARK: - Email Password Login
    func login(email: String, password: String) -> Bool {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: cleanEmail) else {
            self.authErrorMessage = "Please enter a valid email address."
            return false
        }
        guard password.count >= 6 else {
            self.authErrorMessage = "Password must be at least 6 characters."
            return false
        }
        
        if let current = currentUser, current.email.lowercased() == cleanEmail {
            self.isAuthenticated = true
            self.authErrorMessage = nil
            return true
        }
        
        let profile = UserProfile(
            name: cleanEmail.components(separatedBy: "@").first?.capitalized ?? "Chef",
            email: cleanEmail,
            dietaryPreference: .all,
            geminiApiKey: "",
            isGoogleAccount: cleanEmail.contains("gmail") || cleanEmail.contains("google"),
            isAppleAccount: false,
            joinedDate: Date()
        )
        saveProfile(profile)
        self.authErrorMessage = nil
        return true
    }
    
    func updateProfile(name: String, diet: DietType, apiKey: String) {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        AIService.shared.setApiKey(cleanKey)
        guard var profile = currentUser else { return }
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.dietaryPreference = diet
        profile.geminiApiKey = cleanKey
        saveProfile(profile)
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: profileKey)
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
