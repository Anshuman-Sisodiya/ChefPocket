import Foundation
import SwiftUI

struct UserProfile: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var email: String
    var dietaryPreference: DietType = .all
    var geminiApiKey: String = ""
    var joinedDate: Date = Date()
}

class AuthManager: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated: Bool = false
    
    private let profileKey = "chefpocket_saved_user_profile"
    private let usersDatabaseKey = "chefpocket_users_db"
    
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
    
    func signUp(name: String, email: String, password: String, diet: DietType) -> Bool {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, cleanEmail.contains("@") else { return false }
        
        let newProfile = UserProfile(
            name: cleanName,
            email: cleanEmail,
            dietaryPreference: diet,
            geminiApiKey: "",
            joinedDate: Date()
        )
        
        saveProfile(newProfile)
        return true
    }
    
    func login(email: String, password: String) -> Bool {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard cleanEmail.contains("@") else { return false }
        
        // If logging in to existing profile or creating standard profile session
        if let current = currentUser, current.email.lowercased() == cleanEmail {
            self.isAuthenticated = true
            return true
        }
        
        // Default login recovery
        let profile = UserProfile(
            name: cleanEmail.components(separatedBy: "@").first?.capitalized ?? "Chef",
            email: cleanEmail,
            dietaryPreference: .all,
            geminiApiKey: "",
            joinedDate: Date()
        )
        saveProfile(profile)
        return true
    }
    
    func updateProfile(name: String, diet: DietType, apiKey: String) {
        guard var profile = currentUser else { return }
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.dietaryPreference = diet
        profile.geminiApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        saveProfile(profile)
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: profileKey)
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
