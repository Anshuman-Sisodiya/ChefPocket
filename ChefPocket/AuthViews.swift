import SwiftUI

// MARK: - User Profile & Settings View
struct UserProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var store: RecipeStore
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var syncService = CloudSyncService.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var systemColorScheme
    
    @State private var name: String = ""
    @State private var dietaryPreference: DietType = .all
    @State private var apiKey: String = ""
    @State private var showingSaveAlert = false
    @State private var showingLogoutConfirm = false
    @State private var showingExportSheet = false
    @State private var exportURL: URL? = nil
    @State private var showingImportPicker = false
    @State private var showingImportAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: User Account Header
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 54, height: 54)
                            Text(avatarInitials)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(auth.currentUser?.name ?? "Guest Chef")
                                    .font(.headline)
                                if auth.currentUser?.isGoogleAccount == true {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                }
                            }
                            Text(auth.currentUser?.email ?? "Not logged in")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if auth.currentUser?.isGoogleAccount == true {
                                Text("Google Account Linked")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Section 2: Cloud Sync & Cross-Device Backup (Google Account)
                Section(header: Text(languageManager.t("cloud_sync")), footer: Text("All your custom recipes, favorites, and groceries sync automatically with your Google account across all devices.")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(syncService.syncStatus)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if let last = syncService.lastSyncDate {
                                Text("Last synced: \(last.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if syncService.isSyncing {
                            ProgressView()
                        } else {
                            Button(languageManager.t("sync_now")) {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                syncService.syncKitchenData(store: store, auth: auth)
                            }
                            .font(.caption)
                            .bold()
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                    }
                    
                    if !syncService.syncSummary.isEmpty {
                        Text(syncService.syncSummary)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: exportKitchenBackup) {
                        Label("Export Kitchen Backup (.chefpocket)", systemImage: "square.and.arrow.up")
                            .font(.subheadline)
                    }
                }
                
                // Section 3: Appearance & Theme
                Section(header: Text(languageManager.t("theme")), footer: Text("ChefPocket automatically syncs your home screen app icon to match your selected theme.")) {
                    Picker("Theme", selection: $themeManager.appTheme) {
                        Text(languageManager.t("theme_system")).tag("system")
                        Text(languageManager.t("theme_light")).tag("light")
                        Text(languageManager.t("theme_dark")).tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: themeManager.appTheme) { newTheme in
                        themeManager.syncAppIcon(systemIsDark: systemColorScheme == .dark)
                    }
                }
                
                // Section 4: App Language
                Section(header: Text(languageManager.t("language")), footer: Text("Select your preferred language for all recipes, filters, and cooking guides.")) {
                    Picker("Language", selection: $languageManager.currentLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            HStack {
                                Text(lang.flag)
                                Text(lang.displayName)
                            }
                            .tag(lang)
                        }
                    }
                }
                
                // Section 5: Profile Details
                Section(header: Text("Culinary Profile")) {
                    TextField("Full Name", text: $name)
                    
                    Picker("Dietary Preference", selection: $dietaryPreference) {
                        Text("All Dishes").tag(DietType.all)
                        Text("Pure Vegetarian").tag(DietType.veg)
                        Text("Non-Vegetarian").tag(DietType.nonVeg)
                    }
                }
                
                // Section 6: AI Video Extractor Settings
                Section(header: Text("AI Video Recipe Extractor"), footer: Text("Configure a free Google Gemini API Key from aistudio.google.com to extract precise ingredients and whistle counts from YouTube Shorts & Instagram Reels.")) {
                    SecureField("Google Gemini API Key", text: $apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                // Section 7: Save & Log Out
                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                }
                
                Section {
                    Button(role: .destructive, action: { showingLogoutConfirm = true }) {
                        HStack {
                            Spacer()
                            Text(languageManager.t("logout"))
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(languageManager.t("settings"))
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
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareActivityView(activityItems: [url])
                }
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
    
    private func exportKitchenBackup() {
        let email = auth.currentUser?.email ?? "guest"
        if let url = syncService.exportBackup(store: store, email: email) {
            exportURL = url
            showingExportSheet = true
        }
    }
}

// MARK: - Login & Sign Up Modal
struct AuthModalView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var store: RecipeStore
    @ObservedObject var languageManager = LanguageManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var isSignUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedDiet: DietType = .all
    @State private var errorMessage: String? = nil
    @State private var showingGooglePrompt = false
    @State private var googleEmailInput = ""
    @State private var googleNameInput = ""
    
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
                        
                        Text(isSignUp ? "Personalize your cooking, dietary preferences & recipes" : "Log in to sync your recipes & favorites across all devices")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                    
                    // GOOGLE ONE-TAP SIGN IN BUTTON
                    VStack(spacing: 12) {
                        Button(action: { showingGooglePrompt = true }) {
                            HStack(spacing: 10) {
                                Image(systemName: "g.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.red)
                                Text("Continue with Google Account")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(.systemGray4), lineWidth: 1.5)
                                    )
                            )
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Rectangle().fill(Color(.systemGray4)).frame(height: 1)
                            Text("or with email")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Rectangle().fill(Color(.systemGray4)).frame(height: 1)
                        }
                        .padding(.horizontal, 30)
                    }
                    
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
            .alert("Sign in with Google", isPresented: $showingGooglePrompt) {
                TextField("Google Email (e.g. chef@gmail.com)", text: $googleEmailInput)
                TextField("Your Name", text: $googleNameInput)
                Button("Sign In") {
                    if !googleEmailInput.isEmpty {
                        auth.loginWithGoogle(email: googleEmailInput, name: googleNameInput)
                        CloudSyncService.shared.syncKitchenData(store: store, auth: auth)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter your Google Account email to sync your custom recipes, favorites, and groceries across all devices.")
            }
        }
    }
    
    private func handleAuth() {
        errorMessage = nil
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanEmail.contains("@") else {
            errorMessage = "Please enter a valid email address."
            return
        }
        guard password.count >= 4 else {
            errorMessage = "Password must be at least 4 characters."
            return
        }
        
        if isSignUp {
            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = "Please enter your name."
                return
            }
            let success = auth.signUp(name: name, email: cleanEmail, password: password, diet: selectedDiet)
            if success {
                CloudSyncService.shared.syncKitchenData(store: store, auth: auth)
                dismiss()
            } else {
                errorMessage = "Could not create account. Please check your details."
            }
        } else {
            let success = auth.login(email: cleanEmail, password: password)
            if success {
                CloudSyncService.shared.syncKitchenData(store: store, auth: auth)
                dismiss()
            } else {
                errorMessage = "Invalid credentials. Please try again."
            }
        }
    }
}
