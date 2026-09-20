import SwiftUI

struct UserProfileSheet: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var dietaryPreference: DietType = .all
    @State private var apiKey: String = ""
    @State private var showingSaveAlert = false
    @State private var showingLogoutConfirm = false
    
    var body: some View {
        NavigationStack {
            Form {
                // User Avatar & Header
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color.orange.opacity(0.8), Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 58, height: 58)
                            
                            Text(avatarInitials)
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(auth.currentUser?.name ?? "Guest Chef")
                                .font(.headline)
                            Text(auth.currentUser?.email ?? "Guest Mode")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                // Culinary Kitchen Stats
                Section("Kitchen Activity") {
                    HStack {
                        ActivityStatItem(title: "Curated", value: "\(store.curatedRecipes.count)", icon: "book.fill", color: .orange)
                        Divider()
                        ActivityStatItem(title: "My Recipes", value: "\(store.myRecipes.count)", icon: "fork.knife", color: .blue)
                        Divider()
                        ActivityStatItem(title: "Favorites", value: "\(store.recipes.filter { $0.isFavorite }.count)", icon: "heart.fill", color: .red)
                    }
                    .padding(.vertical, 4)
                }
                
                // Dietary Preferences
                Section("Dietary Preference") {
                    Picker("Default Diet", selection: $dietaryPreference) {
                        Text("All Dishes").tag(DietType.all)
                        Text("Pure Vegetarian").tag(DietType.veg)
                        Text("Non-Vegetarian").tag(DietType.nonVeg)
                    }
                    .pickerStyle(.menu)
                }
                
                // AI Video Extractor Settings
                Section(header: Text("AI Video Recipe Extractor"), footer: Text("Configure a free Google Gemini API Key from aistudio.google.com to extract precise ingredients and whistle counts from YouTube Shorts & Instagram Reels.")) {
                    SecureField("Google Gemini API Key", text: $apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    HStack {
                        Label("Daily AI Extractions", systemImage: "sparkles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(AIService.shared.remainingDailyRequests) of 25 left today")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.orange)
                    }
                }
                
                // Profile Edit Details
                Section("Profile Details") {
                    TextField("Display Name", text: $name)
                }
                
                // Save Button
                Section {
                    Button(action: saveChanges) {
                        Text("Save Profile Changes")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .bold()
                            .foregroundColor(.orange)
                    }
                }
                
                // Logout / Account Switch
                Section {
                    Button(role: .destructive, action: { showingLogoutConfirm = true }) {
                        HStack {
                            Spacer()
                            Text(auth.isAuthenticated ? "Log Out" : "Reset Session")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                name = auth.currentUser?.name ?? ""
                dietaryPreference = auth.currentUser?.dietaryPreference ?? store.selectedDiet
                apiKey = auth.currentUser?.geminiApiKey ?? ""
            }
            .alert("Profile Updated", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your culinary preferences and settings have been saved.")
            }
            .confirmationDialog("Log Out", isPresented: $showingLogoutConfirm, titleVisibility: .visible) {
                Button("Log Out", role: .destructive) {
                    auth.logout()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to log out of your ChefPocket account?")
            }
        }
    }
    
    private var avatarInitials: String {
        guard let name = auth.currentUser?.name, !name.isEmpty else { return "CP" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    private func saveChanges() {
        auth.updateProfile(name: name, diet: dietaryPreference, apiKey: apiKey)
        store.selectedDiet = dietaryPreference
        showingSaveAlert = true
    }
}

struct ActivityStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .bold()
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Login & Sign Up Modal
struct AuthModalView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var isSignUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedDiet: DietType = .all
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Brand
                    VStack(spacing: 8) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.orange)
                        
                        Text(isSignUp ? "Join ChefPocket" : "Welcome Back")
                            .font(.title)
                            .bold()
                        
                        Text(isSignUp ? "Personalize your cooking, dietary preferences & recipes" : "Log in to access your culinary collection")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                    
                    // Segmented Mode
                    Picker("Auth Mode", selection: $isSignUp) {
                        Text("Log In").tag(false)
                        Text("Create Account").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Form Fields
                    VStack(spacing: 14) {
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Full Name")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                TextField("e.g. Anshuman", text: $name)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            TextField("name@example.com", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            SecureField("••••••••", text: $password)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Dietary Preference")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Picker("Diet", selection: $selectedDiet) {
                                    Text("All Dishes").tag(DietType.all)
                                    Text("Pure Vegetarian").tag(DietType.veg)
                                    Text("Non-Vegetarian").tag(DietType.nonVeg)
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        
                        if let err = errorMessage {
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: handleAuth) {
                            Text(isSignUp ? "Create Free Account" : "Log In")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button("Continue as Guest") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func handleAuth() {
        errorMessage = nil
        if isSignUp {
            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = "Please enter your name."
                return
            }
            guard email.contains("@") else {
                errorMessage = "Please enter a valid email address."
                return
            }
            guard password.count >= 4 else {
                errorMessage = "Password must be at least 4 characters."
                return
            }
            
            if auth.signUp(name: name, email: email, password: password, diet: selectedDiet) {
                dismiss()
            } else {
                errorMessage = "Could not create account. Please check details."
            }
        } else {
            guard email.contains("@") else {
                errorMessage = "Please enter your email."
                return
            }
            guard !password.isEmpty else {
                errorMessage = "Please enter your password."
                return
            }
            
            if auth.login(email: email, password: password) {
                dismiss()
            } else {
                errorMessage = "Invalid login credentials."
            }
        }
    }
}
